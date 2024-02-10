package com.valhalla.valhalla

class ValhallaKotlin {
    companion object {
        init {
            System.loadLibrary("valhalla-wrapper")
        }
    }

    external fun route(request: String, configPath: String): String
}