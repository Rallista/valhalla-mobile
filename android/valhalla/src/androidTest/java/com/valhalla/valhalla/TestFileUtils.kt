package com.valhalla.valhalla

import android.content.Context
import com.valhalla.valhalla.files.ValhallaFile
import com.valhalla.valhalla.files.copyAssetFileToStorage
import com.valhalla.valhalla.files.loadAssetFile

class TestFileUtils {

  companion object {
    fun getConfigPath(context: Context): String {
      ValhallaFile.copyAssetFileToStorage(context, "valhalla_tiles.tar")
      return ValhallaFile.copyAssetFileToStorage(context, "config.json")
    }

    fun getExpectedResponse(context: Context): String {
      return ValhallaFile.loadAssetFile(context, "expected.json")
    }
  }
}
