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

import android.net.http.X509TrustManagerExtensions;
import android.support.annotation.NonNull;


public abstract class HttpClientAndroid extends AsyncTask<Void, Void, Long> {

    private byte[] _clientCertificate;
    private String _clientCertificatePassword;

    private String _url;
    private String _httpMethod;
    private boolean _followRedirects;
    private String _proxyAddress;
    private int _proxyPort;
    private int _timeout;
    private Map<String, List<String>> _headers;
    private boolean _enableCache;

    public abstract void onHeadersReceived(HttpURLConnection urlConnection);

    public abstract void onFailure(String response);

    public abstract boolean onCheckServerTrusted(List<byte[]> asn1derEncodedCert, boolean chainError);


    public HttpClientAndroid(String url, String httpMethod, Map<String, List<String>> headers, boolean followRedirects, String proxyAddress, int proxyPort, int timeout, boolean enableCache) {
        _url = url;
        _httpMethod = httpMethod;
        _headers = headers;
        _followRedirects = followRedirects;
        _proxyPort = proxyPort;
        _timeout = timeout;
        _proxyAddress = proxyAddress;
        _enableCache = enableCache;
    }

    protected Long doInBackground(Void... args) {
        try {
            /*HttpsURLConnection.setDefaultHostnameVerifier();
              HttpsURLConnection.setDefaultSSLSocketFactory(context.getSocketFactory());
            }*/

            // TODO: READ https://stackoverflow.com/questions/1936872/how-to-keep-multiple-java-httpconnections-open-to-same-destination/1936965#1936965
            HttpURLConnection connection = null;
            try {
                Proxy proxy = Proxy.NO_PROXY;
                if (_proxyAddress != null)
                    proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(_proxyAddress, _proxyPort));

                URL url = new URL(_url);
                connection = (HttpURLConnection) url.openConnection(proxy);

                connection.setConnectTimeout(_timeout);
                connection.setReadTimeout(_timeout);
                connection.setUseCaches(_enableCache);
                connection.setRequestMethod(_httpMethod);
                //connection.setDoOutput(hasPayload);
                connection.setDoInput(true);
                connection.setInstanceFollowRedirects(_followRedirects);

                // the following does not work!!
                System.setProperty("http.keepAlive", "false");
                connection.setRequestProperty("Accept-Encoding", null);
                connection.setRequestProperty("User-Agent", null);
                connection.setRequestProperty("Connection", null);

                for (Map.Entry<String, List<String>> entry : _headers.entrySet()) {
                    for(String value : entry.getValue())
                        connection.addRequestProperty(entry.getKey(), value);
                }

                if (connection instanceof HttpsURLConnection) {
                    HttpsURLConnection sslConnection = configureSecureConnection((HttpsURLConnection)connection);
                    sslConnection.connect();
                } else {
                    connection.connect();
                }
                onHeadersReceived(connection);

            } catch (KeyManagementException | NoSuchAlgorithmException e) {
                e.printStackTrace();
            } catch(SocketTimeoutException e) {
                //onTimeout();
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
