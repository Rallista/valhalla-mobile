package com.valhalla.valhalla

data class ErrorResponse(val code: Int, val message: String) {
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
  class Internal(response: ErrorResponse) : ValhallaException(response.toString(), null)

  /**
   * No longer thrown.
   *
   * [Valhalla.route] used to guess at whether a response was an error by looking for substrings in
   * it, and raised this when the guess was wrong. It now applies the same `failOnUnknown` test as
   * every other action, which either recognises the envelope or does not — so a response that
   * cannot be read is reported as [InvalidResponse], carrying the parse failure that explains it.
   */
  @Deprecated(
      "Never thrown; a response that cannot be read is reported as InvalidResponse.",
      ReplaceWith("ValhallaException.InvalidResponse"))
  class InvalidError : ValhallaException("Invalid error response data")

  /**
   * The engine answered, but the answer could not be read as the response type that was expected.
   *
   * @constructor Carries the underlying parse failure when there was one, so a caller can tell a
   *   malformed payload from one whose shape has drifted from the models.
   */
  class InvalidResponse : ValhallaException {
    constructor() : super("Invalid response data")

    constructor(cause: Throwable) : super("Invalid response data", cause)
  }

  class NotSupported : ValhallaException("The format is not currently supported")
}
