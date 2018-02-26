package com.fusetools.http;

import android.os.AsyncTask;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.MalformedURLException;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.net.Proxy;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.KeyStore;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateExpiredException;
import java.security.cert.CertificateNotYetValidException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Dictionary;
import java.util.List;
import java.util.Map;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.net.ssl.TrustManagerFactory;

import android.util.Log;
import android.net.http.X509TrustManagerExtensions;
import android.support.annotation.NonNull;


public class HttpClientAndroid extends AsyncTask<Void, Void, Long> {

    private HttpMessage message;

    public HttpClientAndroid(HttpMessage message) {

        this.message = message;
    }

    protected Long doInBackground(Void... args) {
        /*HttpsURLConnection.setDefaultHostnameVerifier();
          HttpsURLConnection.setDefaultSSLSocketFactory(context.getSocketFactory());
        }*/

        // TODO: READ https://stackoverflow.com/questions/1936872/how-to-keep-multiple-java-httpconnections-open-to-same-destination/1936965#1936965
        HttpURLConnection connection = null;

        try {
            Proxy proxy = Proxy.NO_PROXY;
            if (this.message.getProxyAddress() != null)
                proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(this.message.getProxyAddress(), this.message.getProxyPort()));

            URL url = new URL(this.message.getUrl());
            connection = (HttpURLConnection) url.openConnection(proxy);
            connection.setConnectTimeout(this.message.getTimeout());
            connection.setReadTimeout(this.message.getTimeout());
            connection.setUseCaches(this.message.enableCache());
            connection.setRequestMethod(this.message.getHttpMethod());
            //connection.setDoOutput(hasPayload);
            connection.setDoInput(true);
            connection.setInstanceFollowRedirects(this.message.followRedirects());

            // the following does not work!!
            System.setProperty("http.keepAlive", "false");

            /*connection.setRequestProperty("Accept-Encoding", "");
            connection.setRequestProperty("User-Agent", "");
            connection.setRequestProperty("Connection", "close"); //Keep-Alive*/
            for (Map.Entry<String, List<String>> entry : this.message.getHeaders().entrySet()) {
                for(String value : entry.getValue()) {
                    connection.addRequestProperty(entry.getKey(), value);
                }
            }

            if (connection instanceof HttpsURLConnection) {
                HttpsURLConnection sslConnection = configureSecureConnection((HttpsURLConnection)connection);
                sslConnection.connect();
            } else {
                connection.connect();
            }

            this.message.onHeadersReceived(connection);
        } catch (KeyManagementException | NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch(SocketTimeoutException e) {
            this.message.onTimeout(e.getMessage());
        } catch (Exception e) {
            this.message.onFailure(e.getMessage());
             e.printStackTrace();
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
        return 0L;
    }

    @NonNull
    private HttpsURLConnection configureSecureConnection(HttpsURLConnection connection) throws KeyStoreException, IOException, NoSuchAlgorithmException, CertificateException, UnrecoverableKeyException, KeyManagementException {
        HttpsURLConnection sslConnection = connection;
        final String requestedHost = connection.getURL().getHost();
        sslConnection.setHostnameVerifier(new HostnameVerifier(){
            public boolean verify(String hostname, SSLSession session) {
                return requestedHost.equals(hostname);
            }});

        javax.net.ssl.KeyManager[] keyManagers = null;
        KeyStore keyStore = null;
        /*if (this.message._clientCertificate != null) {
            InputStream fis =  new ByteArrayInputStream(_clientCertificate);
            keyStore = KeyStore.getInstance("PKCS12");
            keyStore.load(fis, _clientCertificatePassword.toCharArray());

            javax.net.ssl.KeyManagerFactory kmf = javax.net.ssl.KeyManagerFactory.getInstance("X509");
            kmf.init(keyStore, _clientCertificatePassword.toCharArray());
            keyManagers = kmf.getKeyManagers();
        }*/
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(keyStore);

        // this needs to be moved to http client level to be reused across connections
        TrustManager[] trustManagers = tmf.getTrustManagers();
        X509TrustManager tm = (X509TrustManager) trustManagers[0];
        SSLContext context = SSLContext.getInstance("TLS");
        context.init(keyManagers, new X509TrustManager[]{ new CustomX509TrustManager(tm, requestedHost) }, null);

        if (context != null) {
            sslConnection.setSSLSocketFactory(context.getSocketFactory());
        }
        return sslConnection;
    }

    protected void onProgressUpdate(Integer... progress) {
    }

    protected void onPostExecute(Long result) {
    }

    public void AddClientCertificate(byte[] data, String password) {
        //_clientCertificate = data;
        //_clientCertificatePassword = password;
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

            boolean trusted = message.onCheckServerTrusted(encodedChain, chainError);
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
