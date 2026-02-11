package com.valhalla.valhalla

import android.content.Context
import com.valhalla.valhalla.files.ValhallaFile
import com.valhalla.valhalla.files.copyAssetFileToStorage

class TestFileUtils {

  companion object {
    fun getConfigPath(context: Context): String {
      ValhallaFile.copyAssetFileToStorage(context, "valhalla_tiles.tar")
      return ValhallaFile.copyAssetFileToStorage(context, "config.json")
    }


  }
}
