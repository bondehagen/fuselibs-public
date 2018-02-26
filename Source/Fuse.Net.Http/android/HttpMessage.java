package com.fusetools.http;


import java.net.HttpURLConnection;
import java.util.List;
import java.util.Map;

public abstract class HttpMessage {

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

    public abstract void onFailure(String message);
    public abstract void onTimeout(String message);

    public abstract boolean onCheckServerTrusted(List<byte[]> asn1derEncodedCert, boolean chainError);


    public HttpMessage(String url, String httpMethod, Map<String, List<String>> headers, boolean followRedirects, String proxyAddress, int proxyPort, int timeout, boolean enableCache) {
        _url = url;
        _httpMethod = httpMethod;
        _headers = headers;
        _followRedirects = followRedirects;
        _proxyPort = proxyPort;
        _timeout = timeout;
        _proxyAddress = proxyAddress;
        _enableCache = enableCache;
    }

    public String getUrl() {
        return _url;
    }

    public String getHttpMethod() {
        return _httpMethod;
    }

    public boolean followRedirects() {
        return _followRedirects;
    }

    public String getProxyAddress() {
        return _proxyAddress;
    }

    public int getProxyPort() {
        return _proxyPort;
    }

    public int getTimeout() {
        return _timeout;
    }

    public Map<String, List<String>> getHeaders() {
        return _headers;
    }

    public boolean enableCache() {
        return _enableCache;
    }
}
