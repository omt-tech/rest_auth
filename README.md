# RestAuth

[![Build Status](https://api.travis-ci.org/omttech/rest_auth.svg?branch=master)](https://travis-ci.org/omttech/rest_auth)

`RestAuth` is a declarative ACL library for Phoenix. 

## Installation

The library is available on Hex.

```elixir
defp deps do
  [{:rest_auth, "~> 1.0"}]
end
```

The documentation can be accessed at [https://hexdocs.pm/rest_auth](https://hexdocs.pm/rest_auth).

## Functionality

It functions by declaring a controller level plug with a set of roles specified
for the given action. It also provides a framework for doing per-item-ACL with
a naive distributed ETS backend caching built-in.

To set up and use `RestAuth` you need to specify some configuration for sane
defaults. All the configuration is provided using a plug:

    plug RestAuth.Configure, handler: MyHandler

The only option accepted right now is the `:handler` module that implements
the `RestAuth.Handler` behaviour. An example handler is provided in the
`examples/dummy_handler.ex` file.

You also need to set up an authentication controller of sorts that calls
`RestAuth.Controller.login/3` and `RestAuth.Controller.logout/3` functions

A typical sample usage in a controller looks like so (pulled from `RestAuth.Restrict` documentation):

    @rest_auth_roles  [
      {:index, ["user"]},
      {:create, ["admin"]},
      {:update, ["admin"]},
      {:show, ["admin"]},
      {:delete, ["admin"]}
    ]
    plug RestAuth.Restrict, @rest_auth_roles

The handler module provided by the user takes full responsibility for loading
user data from the database and caching the data using `RestAuth.CacheService`
if caching is required.

This library aims to be a slightly opinionated framework for you to build your
own logic on top of. After having implemented the behaviour `RestAuth` should
rarely get in the way of anything.

## State of the project

The project is used in production. That said there are couple things that
remain to be done:
  
  * Generators that make skeleton handler modules
  * Generators for token and user schemas for Ecto
  * Periodic reading from the database to flush the token cache for multi node deploys where the nodes are not connected

## License

RestAuth is released under the MIT License - see the [LICENSE](LICENSE) file.
