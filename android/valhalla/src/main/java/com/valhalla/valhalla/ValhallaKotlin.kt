package com.valhalla.valhalla

internal class ValhallaKotlin {
  companion object {
    init {
      System.loadLibrary("valhalla-wrapper")
    }
  }

  external fun route(request: String, configPath: String): String

  external fun traceRoute(request: String, configPath: String): String

  external fun traceAttributes(request: String, configPath: String): String
}
