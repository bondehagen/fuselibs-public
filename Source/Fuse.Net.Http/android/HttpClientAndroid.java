package com.fusetools.http;

import android.os.AsyncTask;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.Proxy;
import java.net.InetSocketAddress;
import java.security.KeyManagementException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateExpiredException;
import java.security.cert.CertificateNotYetValidException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.net.ssl.TrustManagerFactory;

import android.net.http.X509TrustManagerExtensions;
import android.util.Base64;


public abstract class HttpClientAndroid extends AsyncTask<URL, Integer, Long> {

	private InputStream _clientCertificate;

	public abstract void onHeadersReceived(HttpURLConnection urlConnection);

	public abstract void onFailure(String response);

	public abstract boolean onCheckServerTrusted(List<byte[]> asn1derEncodedCert, boolean chainError);

	public void createRequest(String uri, String method, String proxyHost, int proxyPort) {

		/*HttpsURLConnection.setDefaultHostnameVerifier();
		  HttpsURLConnection.setDefaultSSLSocketFactory(context.getSocketFactory());
		}*/

		try {
			URL url = new URL(uri);
			/*
			  new AsyncTask<Void, String, String>() {
					@Override
					protected void onPreExecute() {
					}

					@Override
					protected String doInBackground(Void... params) {
					}
			  }.execute();
			*/
			execute(url);
		} catch (MalformedURLException e) {
			e.printStackTrace();
		}
	}


	protected Long doInBackground(URL... urls) {

		try {
			URL url = urls[0];

			// TODO: READ https://stackoverflow.com/questions/1936872/how-to-keep-multiple-java-httpconnections-open-to-same-destination/1936965#1936965
			HttpURLConnection connection = null;
			try {
				//Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress("192.168.1.233", 8080));
				Proxy proxy = Proxy.NO_PROXY;
				connection = (HttpURLConnection) url.openConnection(proxy);
				connection.setRequestMethod("GET");
				connection.setConnectTimeout(3000);
				connection.setReadTimeout(3000);

				connection.setRequestMethod("GET");
				// Already true by default but setting just in case; needs to be true since this request
				// is carrying an input (response) body.
				connection.setDoInput(true);

				/*
				// disable response caching
						android.net.http.HttpResponseCache.setDefault(null);
						// disable keepAlive
						System.setProperty("http.keepAlive", "false");
						// don't follow redirects
						HttpsURLConnection.setFollowRedirects(false);
				*/
				try {
					if (!(connection instanceof HttpsURLConnection)) {
						connection.connect();
					} else {
						HttpsURLConnection sslConnection = (HttpsURLConnection) connection;
						/*sslConnection.setHostnameVerifier(new HostnameVerifier(){
							public boolean verify(String hostname, SSLSession session) {
								System.out.println(hostname);
								return true;
							}});*/



						InputStream fis = _clientCertificate;
						String clientCertPassword = "1234";

						KeyStore keyStore = KeyStore.getInstance("PKCS12");
						keyStore.load(fis, clientCertPassword.toCharArray());

						javax.net.ssl.KeyManagerFactory kmf = javax.net.ssl.KeyManagerFactory.getInstance("X509");
						kmf.init(keyStore, clientCertPassword.toCharArray());

						javax.net.ssl.KeyManager[] keyManagers = kmf.getKeyManagers();

						TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
						tmf.init(keyStore);

						TrustManager[] trustManagers = tmf.getTrustManagers();
						X509TrustManager tm = (X509TrustManager) trustManagers[0];

						SSLContext context = SSLContext.getInstance("TLS");
						context.init(keyManagers, new X509TrustManager[]{new CustomX509TrustManager(tm, url.getHost())}, null);

						if (context != null) {
							sslConnection.setSSLSocketFactory(context.getSocketFactory());
						}

						sslConnection.connect();
					}
					onHeadersReceived(connection);

				} catch (KeyManagementException | NoSuchAlgorithmException e) {
					e.printStackTrace();
				}
				//publishProgress(DownloadCallback.Progress.CONNECT_SUCCESS);

				//publishProgress(DownloadCallback.Progress.GET_INPUT_STREAM_SUCCESS, 0);
			} catch (Exception e) {
				onFailure(e.getMessage());
			} finally {
				if (connection != null) {
					connection.disconnect();
				}
			}
		} catch (Exception e) {
			onFailure(e.getMessage());
		}

		return 0L;
	}

	// This is called each time you call publishProgress()
	protected void onProgressUpdate(Integer... progress) {
		//setProgressPercent(progress[0]);
	}

	// This is called when doInBackground() is finished
	protected void onPostExecute(Long result) {
		//showNotification("Downloaded " + result + " bytes");
	}

	public void AddClientCertificate(InputStream inputStream) {
		_clientCertificate = inputStream;
	}

	class CustomX509TrustManager implements X509TrustManager {

		private final X509TrustManagerExtensions tmx;
		private final String serverHostname;

		public CustomX509TrustManager(X509TrustManager tm, String serverHostname) {
			this.serverHostname = serverHostname;
			this.tmx = new X509TrustManagerExtensions(tm);
		}

		public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
			throw new CertificateException("Client certificates not supported!");
		}

		public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
			boolean chainError = false;
			X509Certificate cert = chain[0];
			try {
				cert.checkValidity();
			} catch (CertificateExpiredException cee) {
				chainError = true;
				cee.printStackTrace();
			} catch (CertificateNotYetValidException cnyv) {
				chainError = true;
				cnyv.printStackTrace();
			}
			List<X509Certificate> trustedChain = new ArrayList<>();
			Collections.addAll(trustedChain, chain);
			try {
				// https://www.synopsys.com/blogs/software-security/ineffective-certificate-pinning-implementations/
				trustedChain = this.tmx.checkServerTrusted(chain, authType, this.serverHostname);

			} catch (CertificateException ce) {
				chainError = true;
			}
			List<byte[]> encodedChain = new ArrayList<byte[]>();
			for (X509Certificate trustedCert : trustedChain) {
				encodedChain.add(trustedCert.getEncoded());
			}

			boolean trusted = onCheckServerTrusted(encodedChain, chainError);
			if (!trusted)
				throw new CertificateException("Validation procedure trust certificate");
		}

		public X509Certificate[] getAcceptedIssuers() {
			// getAcceptedIssuers is meant to be used to determine which trust anchors the server will
			// accept when verifying clients.
			return new X509Certificate[0];
		}
	}
}
