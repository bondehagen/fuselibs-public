package com.fusetools.http;

import java.net.HttpURLConnection;

public interface MyCallback {
	void onHeadersReceived(HttpURLConnection urlConnection);
    void onFailure(String response);
    boolean onCheckServerTrusted(byte[] asn1derEncodedCert);
}
