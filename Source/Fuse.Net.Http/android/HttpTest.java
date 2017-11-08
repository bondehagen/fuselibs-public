package com.fusetools.http;

import android.os.AsyncTask;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.X509TrustManager;


public class HttpTest {
	
	public MyCallback callback;

	public void createRequest(String uri) {

		/*HttpsURLConnection.setDefaultHostnameVerifier();
		  HttpsURLConnection.setDefaultSSLSocketFactory(context.getSocketFactory());
		}*/

		try {
			URL url = new URL(uri);
			new DownloadFilesTask().execute(url);
		} catch (MalformedURLException e) {
			e.printStackTrace();
		}
	}

	private class DownloadFilesTask extends AsyncTask<URL, Integer, Long> {

		protected Long doInBackground(URL... urls) {

			try {
				URL url = urls[0];

// TODO: READ https://stackoverflow.com/questions/1936872/how-to-keep-multiple-java-httpconnections-open-to-same-destination/1936965#1936965
				InputStream stream = null;
				HttpURLConnection connection = null;
				String result = null;
				try {
					connection = (HttpURLConnection) url.openConnection();

					connection.setConnectTimeout(3000);
					connection.setReadTimeout(3000);

					connection.setRequestMethod("GET");
					// Already true by default but setting just in case; needs to be true since this request
					// is carrying an input (response) body.
					connection.setDoInput(true);


					if (url.getProtocol().equalsIgnoreCase("https")) {
						HttpsURLConnection sslConnection = (HttpsURLConnection)connection;
						sslConnection.setHostnameVerifier(new HostnameVerifier(){
							public boolean verify(String hostname, SSLSession session) {
								System.out.println(hostname);
								return true;
							}});
						SSLContext context = null;
						try {
							context = SSLContext.getInstance("TLS");

							context.init(null, new X509TrustManager[] { new X509TrustManager() {
								public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
									System.out.println(authType);
								}
								public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
									System.out.println(authType);
									X509Certificate cert = chain[0];
									/*try {
										cert.checkValidity();
									} catch(CertificateExpiredException cee) {

									} catch(CertificateNotYetValidException cnyv) {

									}*/

									callback.onCheckServerTrusted(cert.getEncoded());
								}
								public X509Certificate[] getAcceptedIssuers() {
									return new X509Certificate[0];
								}}}, new SecureRandom());

						} catch (KeyManagementException | NoSuchAlgorithmException e) {
							e.printStackTrace();
						}

						if (context != null) {
							sslConnection.setSSLSocketFactory(context.getSocketFactory());
						}
						sslConnection.connect();
						callback.onHeadersReceived(connection);
					} else {
						connection.connect();
						callback.onHeadersReceived(connection);
					}
					
					
					//publishProgress(DownloadCallback.Progress.CONNECT_SUCCESS);

					// Retrieve the response body as an InputStream.
					stream = connection.getInputStream();

					//publishProgress(DownloadCallback.Progress.GET_INPUT_STREAM_SUCCESS, 0);

					if (stream != null) {
						result = readStream(stream);
						//callback.onDone(result);
						//copyInputStreamToFile(stream, System.out);
					}
				} finally {
					if (stream != null) {
						stream.close();
					}
					if (connection != null) {
						connection.disconnect();
					}
				}

			} catch (MalformedURLException e) {
				callback.onFailure(e.getMessage());
			} catch (IOException e) {
				callback.onFailure(e.getMessage());
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
	}

	private void copyInputStreamToFile(InputStream in, PrintStream out) {
		try {
			byte[] buf = new byte[1024];
			int len;
			while((len=in.read(buf))>0){
				out.write(buf,0,len);
			}
			out.close();
			in.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private String readStream(InputStream input) {
		try {
			ByteArrayOutputStream result = new ByteArrayOutputStream();
			byte[] buffer = new byte[1024];
			int length;
			while ((length = input.read(buffer)) != -1) {
				result.write(buffer, 0, length);
			}
			// StandardCharsets.UTF_8.name() > JDK 7

			return result.toString("UTF-8");
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}
}
