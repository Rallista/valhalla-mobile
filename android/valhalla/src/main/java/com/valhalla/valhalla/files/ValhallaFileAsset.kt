package com.valhalla.valhalla.files

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

fun ValhallaFile.Companion.copyAssetFileToStorage(context: Context, assetFileName: String): String {
  val assetManager = context.assets
  val outputFile = File(context.filesDir, assetFileName)

  val inputStream: InputStream = assetManager.open(assetFileName)
  val outputStream = FileOutputStream(outputFile)

  val bufferSize = 1024
  val buffer = ByteArray(bufferSize)
  var read: Int

  while (inputStream.read(buffer, 0, bufferSize).also { read = it } != -1) {
    outputStream.write(buffer, 0, read)
  }

  inputStream.close()
  outputStream.close()

  return outputFile.absolutePath
}

fun ValhallaFile.Companion.loadAssetFile(context: Context, assetFileName: String): String {
  val assetManager = context.assets
  val inputStream: InputStream = assetManager.open(assetFileName)
  val buffer = ByteArray(inputStream.available())
  inputStream.read(buffer)
  inputStream.close()
  return String(buffer)
}
