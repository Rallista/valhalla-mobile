package com.valhalla.valhalla.files

import android.content.Context
import java.io.File

/** Used to provide absolute paths and common file operations for use with valhalla. */
class ValhallaFile(
    private val context: Context,
    private val fileName: String,
    private val filesDir: File = context.filesDir,
) {

  companion object {
    fun usingAsset(context: Context, fileName: String): ValhallaFile {
      copyAssetFileToStorage(context, fileName)
      return ValhallaFile(context, fileName)
    }
  }

  private val file: File
    get() = File(filesDir, fileName)

  fun writeText(text: String) {
    file.writeText(text)
  }

  fun writeBytes(bytes: ByteArray) {
    file.writeBytes(bytes)
  }

  fun absolutePath(): String {
    return file.absolutePath
  }

  fun delete() {
    file.delete()
  }

  fun exists(): Boolean {
    return file.exists()
  }

  // MARK: Asset file operations

}
