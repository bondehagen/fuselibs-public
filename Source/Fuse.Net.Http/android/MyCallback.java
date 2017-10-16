package com.fusetools.http;

public interface MyCallback {
    void onDone(String response);
    boolean onCheckServerTrusted(String subject, String thumbprint);
}
