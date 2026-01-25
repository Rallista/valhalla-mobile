package com.valhalla.valhalla.config

import android.content.Context
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import com.valhalla.config.models.ValhallaConfig
import com.valhalla.valhalla.files.ValhallaFile

/**
 * Manages the Valhalla configuration file within the Android application's
 * available filesystem.
 *
 * @param context The Android context used for file system access.
 * @param file The file handler for the valhalla.json configuration file. Defaults to "valhalla.json" in app storage.
 * @param moshi JSON serialization adapter. Defaults to a Moshi instance with Kotlin reflection support.
 *
 * @see ValhallaConfig
 * @see ValhallaFile
 */
class ValhallaConfigManager(
    private val context: Context,
    private val file: ValhallaFile = ValhallaFile(context, "valhalla.json"),
    private val moshi: Moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
) {

    fun writeConfig(config: ValhallaConfig) {
        val jsonAdapter = moshi.adapter(ValhallaConfig::class.java)
        val json = jsonAdapter.toJson(config)

        // https://developer.android.com/training/data-storage/
        file.writeText(json)
    }

    fun getAbsolutePath(): String {
        return file.absolutePath()
    }
}
