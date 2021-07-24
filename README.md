# Überauth Keycloak

> Keycloak OAuth2 strategy for Überauth, updated for Phoenix 1.5+

## Acknowledgements

This repository is based on the work of [mtchavez/ueberauth_keycloak](https://github.com/mtchavez/ueberauth_keycloak), via [gseddon/ueberauth_keycloak](https://github.com/gseddon/ueberauth_keycloak).

## Installation

1. Add `:ueberauth_keycloak_strategy` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_keycloak_strategy, "~> 0.2"}]
    end
    ```

1. Add Keycloak to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        keycloak: {Ueberauth.Strategy.Keycloak, [default_scope: "email"]}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Keycloak.OAuth,
      client_id: System.get_env("KEYCLOAK_CLIENT_ID"),
      client_secret: System.get_env("KEYCLOAK_CLIENT_SECRET")
      site: "https://example.com/",
      authorize_url: "https://example.com/auth/realms/myrealm/protocol/openid-connect/auth",
      token_url: "https://example.com/auth/realms/buzz/myrealm/openid-connect/token",
      userinfo_url: "https://example.com/auth/realms/myrealm/protocol/openid-connect/userinfo",
    ```


1.  Create the request and callback routes:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example][example-app] application
on how to integrate other strategies. Adding Keycloak should be similar to Github.

## Calling

Depending on the configured url you can initial the request through:

    /auth/keycloak

Or with options:

    /auth/keycloak?scope=profile


```elixir
config :ueberauth, Ueberauth,
  providers: [
    keycloak: {
      Ueberauth.Strategy.Keycloak, [
        default_scope: "profile"
      ]
    }
  ]
```

## Documentation

The docs can be found at [ueberauth_keycloak][package-docs] on [Hex Docs][hex-docs].

[example-app]: https://github.com/ueberauth/ueberauth_example
[hex-docs]: https://hexdocs.pm
[package-docs]: https://hexdocs.pm/ueberauth_keycloak_strategy
