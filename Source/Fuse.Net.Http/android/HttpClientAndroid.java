package com.fusetools.http;

import android.os.AsyncTask;

import java.io.ByteArrayInputStream;
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
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.net.ssl.TrustManagerFactory;

import android.net.http.X509TrustManagerExtensions;
import android.util.Base64;


public abstract class HttpClientAndroid extends AsyncTask<URL, Integer, Long> {

	private byte[] _clientCertificate;
	private String _clientCertificatePassword;

	public abstract void onHeadersReceived(HttpURLConnection urlConnection);

	public abstract void onFailure(String response);

	public abstract boolean onCheckServerTrusted(List<byte[]> asn1derEncodedCert, boolean chainError);

	public void createRequest(String uri, String method, String proxyHost, int proxyPort) {

		try {
			URL url = new URL(uri);
			execute(url);
		} catch (MalformedURLException e) {
			e.printStackTrace();
		}
	}


	protected Long doInBackground(URL... urls) {

		try {
			URL url = urls[0];

			HttpURLConnection connection = null;
			try {
				//Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress("", 8080));
				Proxy proxy = Proxy.NO_PROXY;
				connection = (HttpURLConnection) url.openConnection(proxy);
				connection.setRequestMethod("GET");
				connection.setConnectTimeout(3000);
				connection.setReadTimeout(3000);

				connection.setRequestMethod("GET");
				connection.setDoInput(true);

				try {
					if (!(connection instanceof HttpsURLConnection)) {
						connection.connect();
					} else {
						HttpsURLConnection sslConnection = (HttpsURLConnection) connection;
						sslConnection.setHostnameVerifier(new HostnameVerifier(){
							public boolean verify(String hostname, SSLSession session) {
								return hostname == url.getHost();
							}});
						
						javax.net.ssl.KeyManager[] keyManagers = null;
						KeyStore keyStore = null;
						if (_clientCertificate != null) {
							InputStream fis =  new ByteArrayInputStream(_clientCertificate);
							keyStore = KeyStore.getInstance("PKCS12");
							keyStore.load(fis, _clientCertificatePassword.toCharArray());

							javax.net.ssl.KeyManagerFactory kmf = javax.net.ssl.KeyManagerFactory.getInstance("X509");
							kmf.init(keyStore, _clientCertificatePassword.toCharArray());
							keyManagers = kmf.getKeyManagers();
						}
						TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
						tmf.init(keyStore);

						TrustManager[] trustManagers = tmf.getTrustManagers();
						X509TrustManager tm = (X509TrustManager) trustManagers[0];
						SSLContext context = SSLContext.getInstance("TLS");
						context.init(keyManagers, new X509TrustManager[]{ new CustomX509TrustManager(tm, url.getHost()) }, null);

						if (context != null) {
							sslConnection.setSSLSocketFactory(context.getSocketFactory());
						}

						sslConnection.connect();
					}
					onHeadersReceived(connection);

				} catch (KeyManagementException | NoSuchAlgorithmException e) {
					e.printStackTrace();
				}
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

	protected void onProgressUpdate(Integer... progress) {
	}

	protected void onPostExecute(Long result) {
	}

	public void AddClientCertificate(byte[] data, String password) {
		_clientCertificate = data;
		_clientCertificatePassword = password;
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
			return new X509Certificate[0];
		}
	}
}