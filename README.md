# Überauth RingCentral

> RingCentral OAuth2 strategy for Überauth.

## Acknowledgements

This repository is based on the work of [mtchavez/ueberauth_ring_central](https://github.com/mtchavez/ueberauth_ring_central).

## Installation

1. Add `:ueberauth_ring_central_strategy` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_ring_central_strategy, "~> 0.2"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_ring_central_strategy]]
    end
    ```

1. Add RingCentral to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        ring_central: {Ueberauth.Strategy.RingCentral, [default_scope: "read_user"]}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.RingCentral.OAuth,
      client_id: System.get_env("RING_CENTRAL_CLIENT_ID"),
      client_secret: System.get_env("RING_CENTRAL_CLIENT_SECRET"),
      redirect_uri: System.get_env("RING_CENTRAL_REDIRECT_URI")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example][example-app] application
on how to integrate other strategies. Adding RingCentral should be similar to Github.

## Calling

Depending on the configured url you can initial the request through:

    /auth/ring_central

Or with options:

    /auth/ring_central?scope=profile


```elixir
config :ueberauth, Ueberauth,
  providers: [
    ring_central: {
      Ueberauth.Strategy.RingCentral, [
        default_scope: "profile"
      ]
    }
  ]
```

## Documentation

The docs can be found at [ueberauth_ring_central][package-docs] on [Hex Docs][hex-docs].

[example-app]: https://github.com/ueberauth/ueberauth_example
[hex-docs]: https://hexdocs.pm
[package-docs]: https://hexdocs.pm/ueberauth_ring_central_strategy
