`RestAuth` is a declarative ACL library for Phoenix. It functions by declaring a
  controller level plug with a set of roles specified for the given action. It also
  provides a framework for doing per-item-ACL with ETS backed caching built in.

  To set up and use `RestAuth` you need to specify some configuration for sane defaults
  and specify a handler module based on the `RestAuth.HandlerBehaviour` behaviour.
  
  You also need to set up an authentication controller of sorts that calls  
  `RestAuth.Controller.login/3` and `RestAuth.Controller.logout/3` functions

  A typical sample usage in a controller looks like so (pulled from `Restauth.Restrict` documentation):

  ```
    @rest_auth_roles  [
                        {:index, ["user"]},
                        {:create, ["admin"]},
                        {:update, ["admin"]},
                        {:show, ["admin"]},
                        {:delete, ["admin"]}
                       ]
    plug RestAuth.Restrict, @rest_auth_roles
  ```

  The handler module provided by the user takes full responsibility for loading
  user data from the database and caching the data using `RestAuth.CacheService` etc.
  This library aims to be a slightly oppinionated framework for you to build your own
  logic on top of. After having implemented the behaviour `RestAuth` should rarely get
  in the way of anyhting.

  Our TODO list:
  * Generators that make skeleton handler modules
  * Generators for token and user schemas for Ecto
  * More testing, all testing right now is implicit through the four projects in production using this lib
  * Periodic reading from the database to flush the token cache for multi node deploys where the nodes are not connected