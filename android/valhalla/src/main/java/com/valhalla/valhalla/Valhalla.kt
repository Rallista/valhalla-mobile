package com.valhalla.valhalla

public interface ValhallaProviding {
    fun route(request: String): String
}

public class Valhalla(
    private val configPath: String
): ValhallaProviding {
    private val valhallaKotlin = ValhallaKotlin()

    override fun route(request: String): String {
        return valhallaKotlin.route(request, configPath)
    }
}