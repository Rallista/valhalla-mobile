# JNI bridge: the native libvalhalla-wrapper.so resolves these classes,
# interface methods and data-class getters by name at runtime via
# FindClass / GetMethodID. R8 must not rename or strip them.

-keep class com.valhalla.valhalla.http.ValhallaHttpClient {
    public *;
}

-keep class com.valhalla.valhalla.http.ValhallaHttpClient$GetResponse {
    public *;
}

-keep class com.valhalla.valhalla.http.ValhallaHttpClient$HeadResponse {
    public *;
}
