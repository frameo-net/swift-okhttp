package com.madsodgaard.swiftopenapiokhttp;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

public final class OkHttpCallback implements Callback {
    private final long identifier;

    public OkHttpCallback(long identifier) {
        this.identifier = identifier;
    }

    public long getIdentifier() {
        return identifier;
    }

    @Override
    public void onFailure(Call call, IOException e) {
        onFailure(e.getMessage());
    }

    @Override
    public void onResponse(Call call, Response response) throws IOException {
        System.out.println("Java: onResponse");
        nativeOnResponse(response);
    }

    public native void onFailure(String message);
    public native void nativeOnResponse(Response response);
}
