package com.valhalla.valhalla

data class ErrorResponse<Route>(val code: String, val message: String, val routes: List<Route>) {
  override fun toString(): String {
    return "ValhallaError(code=$code, $message)"
  }
}

sealed class ValhallaException(message: String? = null, cause: Throwable? = null) :
    Exception(message, cause) {
  constructor(cause: Throwable) : this(null, cause)

  /**
   * An error returned by the routing engine. See
   * [Valhalla - Internal Error](https://valhalla.github.io/valhalla/api/turn-by-turn/api-reference/#internal-error-codes-and-conditions)
   *
   * @param response
   * @constructor TODO
   */
  class Internal(response: ErrorResponse<*>) : ValhallaException(response.toString(), null)

  class InvalidError : ValhallaException("Invalid error response data")

  class InvalidResponse : ValhallaException("Invalid response data")

  class NotSupported : ValhallaException("The format is not currently supported")
}
