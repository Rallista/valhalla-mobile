package com.valhalla.valhalla.http

/**
 * Synchronous HTTP client used by Valhalla's `GraphReader` to fetch tile files
 * when the configuration sets `mjolnir.tile_url` and the tile is not already
 * present in the local `tile_dir`.
 *
 * Implementations MUST be thread-safe. Valhalla calls these methods from
 * background worker threads during graph traversal and multiple calls can be
 * in flight concurrently for different tile URLs.
 *
 * Errors are signalled via `success = false` on the response — implementations
 * MUST NOT throw. Exceptions raised here propagate through the JNI bridge into
 * Valhalla's worker threads which are not designed to recover from them.
 *
 * Pass an implementation to [com.valhalla.valhalla.Valhalla]'s constructor.
 * Pass `null` (or omit) to disable HTTP fetching; tiles must then be supplied
 * locally via `mjolnir.tile_extract` or `mjolnir.tile_dir`.
 */
interface ValhallaHttpClient {
  /**
   * Synchronous GET. When [rangeSize] is `0` the implementation should request
   * the full body (no `Range` header). When [rangeSize] is non-zero Valhalla
   * is reading an indexed entry from a single-file tar archive and expects
   * `bytes=<rangeOffset>-<rangeOffset+rangeSize-1>`.
   */
  fun get(url: String, rangeOffset: Long, rangeSize: Long): GetResponse

  /**
   * Synchronous HEAD. [headerMask] is the bitset Valhalla passes via the
   * native `tile_getter_t::header_mask_t` enum. Bit 0 (value `1`) means the
   * caller wants `Last-Modified` reflected back via
   * [HeadResponse.lastModifiedTime]. Other bits are currently unused.
   */
  fun head(url: String, headerMask: Int): HeadResponse

  data class GetResponse(
      val success: Boolean,
      val httpCode: Int = 0,
      val body: ByteArray? = null,
  ) {
    override fun equals(other: Any?): Boolean {
      if (this === other) return true
      if (javaClass != other?.javaClass) return false
      other as GetResponse
      return success == other.success &&
          httpCode == other.httpCode &&
          body.contentEquals(other.body)
    }

    override fun hashCode(): Int {
      var result = success.hashCode()
      result = 31 * result + httpCode
      result = 31 * result + (body?.contentHashCode() ?: 0)
      return result
    }
  }

  data class HeadResponse(
      val success: Boolean,
      val httpCode: Int = 0,
      /** Seconds since the Unix epoch, parsed from `Last-Modified`. `0` if unknown. */
      val lastModifiedTime: Long = 0,
  )

  companion object {
    /** Bit returned to native `tile_getter_t::kHeaderLastModified`. */
    const val HEADER_MASK_LAST_MODIFIED: Int = 1
  }
}
