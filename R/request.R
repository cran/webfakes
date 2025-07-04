#' A webfakes request object
#'
#' webfakes creates a `webfakes_request` object for every incoming HTTP
#' request. This object is passed to every matched route and middleware,
#' until the response is sent. It has reference semantics, so handlers
#' can modify it.
#'
#' Fields and methods:
#'
#' * `app`: The `webfakes_app` object itself.
#' * `headers`: Named list of HTTP request headers.
#' * `hostname`: The Host header, the server hostname and maybe port.
#' * `method`: HTTP method.
#' * `path`: Server path.
#' * `protocol`: `"http"` or `"https"`.
#' * `query_string`: The raw query string, without the starting `?`.
#' * `query`: Parsed query parameters in a named list.
#' * `remote_addr`: String, the domain name or IP address of the client.
#'    webfakes runs on the localhost, so this is `127.0.0.1`.
#' * `url`: The full URL of the request.
#' * `get_header(field)`: Function to query a request header. Returns
#'   `NULL` if the header is not present.
#'
#' Body parsing middleware adds additional fields to the request object.
#' See [mw_raw()], [mw_text()], [mw_json()], [mw_multipart()] and
#' [mw_urlencoded()].
#'
#' @seealso [webfakes_response] for the webfakes response object.
#' @name webfakes_request
#' @examples
#' # This is how you can see the request and response objects:
#' app <- new_app()
#' app$get("/", function(req, res) {
#'   browser()
#'   res$send("done")
#' })
#' app
#'
#' # Now start this app on a port:
#' # app$listen(3000)
#' # and connect to it from a web browser: http://127.0.0.1:3000
#' # You can also use another R session to connect:
#' # httr::GET("http://127.0.0.1:3000")
#' # or the command line curl tool:
#' # curl -v http://127.0.0.1:3000
#' # The app will stop while processing the request.
NULL

new_request <- function(app, self) {
  if (isTRUE(self$.has_methods)) {
    return(self)
  }
  parsed_headers <- self$headers
  self$.has_methods <- TRUE
  self$app <- app
  self$headers <- parsed_headers
  self$hostname <- parsed_headers$host
  self$method <- tolower(self$method)
  self$protocol <- "http"
  self$query = parse_query(self$query_string)
  self$get_header <- function(field) {
    h <- self$headers
    names(h) <- tolower(names(h))
    h[[tolower(field)]]
  }
  rm(parsed_headers)

  self$res <- new_response(app, self)

  class(self) <- c("webfakes_request", class(self))
  self
}

parse_query <- function(query) {
  query <- sub("^[?]", "", query)
  query <- chartr("+", " ", query)
  argstr <- strsplit(query, "&", fixed = TRUE)[[1]]
  argstr <- strsplit(argstr, "=", fixed = TRUE)
  keys <- vapply(argstr, function(x) utils::URLdecode(x[[1]]), character(1))
  vals <- lapply(argstr, function(x) {
    if (length(x) == 2) utils::URLdecode(x[[2]]) else ""
  })
  structure(vals, names = keys)
}
