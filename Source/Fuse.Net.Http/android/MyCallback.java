package com.fusetools.http;

public interface MyCallback {
    void onDone(String response);
    boolean onCheckServerTrusted(String subject, byte[] asn1derEncodedCert);
}
