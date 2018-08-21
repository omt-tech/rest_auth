# Changelog

## v2.0.0 (20.08.2018)

Breaking

  * Update `RestAuth.Controller.login/2` errors return `401` by default instead of `403`

Enhancements

  * Update `RestAuth.Controller` to use the error handler for errors

## v1.1.2 (16.08.2018)

Enhancements

  * Add `RestAuth.ErrorHandler` behaviour to permit customization of `Plug` error responses
  * Add `RestAuth.ErrorHandler.Default` implementation
  * Update `RestAuth.Configure` to allow `:rest_auth_error_handler` to be set
  * Update `RestAuth.Authenticate` and `RestAuth.Restrict` to use the error handler for errors

## v1.1.0 (29.01.2018)

Enhancements

  * Add optional support for [Jason](https://github.com/michalmuskala/jason)

## v1.0.0 (08.08.2017)

Initial stable release.
