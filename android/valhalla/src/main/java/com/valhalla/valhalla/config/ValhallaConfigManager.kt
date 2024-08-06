package com.valhalla.valhalla.config

import android.content.Context
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import com.valhalla.valhalla.files.ValhallaFile

class ValhallaConfigManager(
    private val context: Context,
    private val file: ValhallaFile = ValhallaFile(context, "valhalla.json"),
    private val moshi: Moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
) {

  /**
   * Write a valhalla config file to the device's filesystem.
   *
   * @param config
   */
  fun writeConfig(config: ValhallaConfig) {
    val jsonAdapter = moshi.adapter(ValhallaConfig::class.java)
    val json = jsonAdapter.toJson(config)

    // https://developer.android.com/training/data-storage/
    file.writeText(json)
  }

  /**
   * Get the absolute path of a file in the device's filesystem. This is used by the Valhalla class
   * to read the config file.
   *
   * @param filename The filename of config file you used.
   * @return
   */
  fun getAbsolutePath(): String {
    return file.absolutePath()
  }
}
