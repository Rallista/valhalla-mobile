# Rules shipped to consuming apps, because nothing here survives R8 on its own evidence.

# The tile-fetching client is called from C++, never from Kotlin. Nothing on the JVM side
# references get or head, so R8 sees them as unused and is free to rename or remove them --
# after which the method lookups in src/wrapper/main.cpp fail and every tile fetch reports a
# failure, with no error to explain why.
-keep,includedescriptorclasses class com.valhalla.valhalla.http.ValhallaHttpClient {
    com.valhalla.valhalla.http.ValhallaHttpResponse get(java.lang.String, long, long);
    com.valhalla.valhalla.http.ValhallaHttpResponse head(java.lang.String, int);
}

# The same for the response it hands back. These fields are written by the constructor and read
# only through JNI GetFieldID, by name, so they have to keep the names main.cpp looks up.
-keep,includedescriptorclasses class com.valhalla.valhalla.http.ValhallaHttpResponse {
    boolean success;
    int httpCode;
    long lastModified;
    byte[] body;
}

# The native methods themselves are covered by AGP's default proguard-android-optimize.txt,
# which keeps the names of any class with native members. That does not extend to the two
# classes above, which are ordinary Kotlin reached from the other direction.

# Moshi reflects over the generated request, response, and config models by property name, so
# obfuscating them leaves a config or a request that valhalla cannot read -- silently, since an
# unknown key is skipped rather than reported. These classes are all data holders, so keeping
# their members costs little.
-keep class com.valhalla.config.models.** { *; }
-keep class com.valhalla.api.models.** { *; }
-keepclassmembers class com.valhalla.valhalla.ErrorResponse { *; }

# Moshi's Kotlin reflection adapter needs the metadata that describes default values and
# nullability; without it every model with a default parameter fails to construct.
-keep class kotlin.Metadata { *; }
-keepclassmembers class ** {
    @com.squareup.moshi.Json <fields>;
}
