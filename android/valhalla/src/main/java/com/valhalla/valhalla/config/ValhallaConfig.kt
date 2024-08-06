package com.valhalla.valhalla.config

import com.valhalla.config.models.AdditionalData
import com.valhalla.config.models.Httpd
import com.valhalla.config.models.Loki
import com.valhalla.config.models.Meili
import com.valhalla.config.models.Mjolnir
import com.valhalla.config.models.Odin
import com.valhalla.config.models.ServiceLimits
import com.valhalla.config.models.Statsd
import com.valhalla.config.models.Thor
import com.valhalla.valhalla.files.ValhallaFile

data class ValhallaConfig(
    val additionalData: AdditionalData = AdditionalData(),
    val httpd: Httpd = Httpd(),
    val loki: Loki = Loki(),
    val meili: Meili = Meili(),
    val mjolnir: Mjolnir = Mjolnir(),
    val odin: Odin = Odin(),
    val serviceLimits: ServiceLimits = ServiceLimits(),
    val statsd: Statsd = Statsd(),
    val thor: Thor = Thor()
) {
  companion object {
    fun usingTileTar(
        tileExtract: ValhallaFile,
        trafficExtract: ValhallaFile? = null
    ): ValhallaConfig {
      return ValhallaConfig(
          mjolnir =
              Mjolnir(
                  tileExtract = tileExtract.absolutePath(),
                  trafficExtract = trafficExtract?.absolutePath()))
    }

    fun usingTileDir(tileDir: ValhallaFile, trafficExtract: ValhallaFile? = null): ValhallaConfig {
      return ValhallaConfig(
          mjolnir =
              Mjolnir(
                  tileDir = tileDir.absolutePath(),
                  trafficExtract = trafficExtract?.absolutePath()))
    }
  }
}
