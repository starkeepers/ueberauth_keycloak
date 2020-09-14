defmodule Ueberauth.Strategy.RingCentral do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with RingCentral.

  ### Setup

  Create an application in RingCentral for you to use.

  Register a new application at: [your ring_central developer page](https://ring_central.com/settings/developers) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          ring_central: { Ueberauth.Strategy.RingCentral, [] }
        ]

  Then include the configuration for ring_central.

      config :ueberauth, Ueberauth.Strategy.RingCentral.OAuth,
        client_id: System.get_env("RING_CENTRAL_CLIENT_ID"),
        client_secret: System.get_env("RING_CENTRAL_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end


  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the `uid_field`

      config :ueberauth, Ueberauth,
        providers: [
          ring_central: { Ueberauth.Strategy.RingCentral, [uid_field: :email] }
        ]

  Default is `:id`

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          ring_central: { Ueberauth.Strategy.RingCentral, [default_scope: "api read_user read_registry", api_version: "v4"] }
        ]

  Default is "api read_user read_registry"
  """
  require Logger

  use Ueberauth.Strategy,
    uid_field: :owner_id,
    default_scope: nil,
    oauth2_module: Ueberauth.Strategy.RingCentral.OAuth

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the ring_central authentication page.

  To customize the scope (permissions) that are requested by ring_central include them as part of your url:

      "/auth/ring_central?scope=api read_user read_registry"

  You can also include a `state` param that ring_central will return to you.
  """
  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from RingCentral. When there is a failure from RingCentral the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from RingCentral is returned in the `Ueberauth.Auth` struct.
  """
  @impl Ueberauth.Strategy
  def handle_callback!(%Plug.Conn{params: %{"code" => code} = params} = conn) do
    module = option(conn, :oauth2_module)

    session_state = Map.get(params, "state")

    token = apply(module, :get_token!, [[code: code, redirect_uri: callback_url(conn), state: session_state]])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      put_private(conn, :ring_central_token, token)
    end
  end

  @doc false
  @impl Ueberauth.Strategy
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw RingCentral response around during the callback.
  """
  @impl Ueberauth.Strategy
  def handle_cleanup!(conn) do
    conn
    |> put_private(:ring_central_user, nil)
  end

  @doc """
  Fetches the uid field from the RingCentral response. This defaults to the option `uid_field` which in-turn defaults to `id`
  """
  @impl Ueberauth.Strategy
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.ring_central_token.other_params[uid_field]
  end

  @doc """
  Includes the credentials from the RingCentral response.
  """
  @impl Ueberauth.Strategy
  def credentials(%Plug.Conn{private: %{ring_central_token: token}}), do: credentials(token)
  def credentials(token) do
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, " ")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes,
      other: %{refresh_expires_at: refresh_expires_at(token)}
    }
  end

  defp refresh_expires_at(%{other_params: %{"refresh_token_expires_in" => expires_in}}) do
    OAuth2.Util.unix_now() + expires_in
  end
  defp refresh_expires_at(_), do: nil

  @doc """
  Turns Ueberauth credentials into an OAuth2 Access Token. Useful for requesting refresh tokens.
  """
  @spec ueberauth_to_oauth_token(Ueberauth.Auth.Credentials.t()) :: OAuth2.AccessToken.t()
  def ueberauth_to_oauth_token(credentials) do
    %OAuth2.AccessToken{
      access_token: credentials.token,
      refresh_token: credentials.refresh_token,
      expires_at: credentials.expires_at,
      token_type: credentials.token_type
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the RingCentral callback.
  """
  @impl Ueberauth.Strategy
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.ring_central_token
      }
    }
  end

  @spec logout(Ueberauth.Auth.Credentials.t()) :: {:ok, OAuth2.Response} | {:error, any}
  def logout(credentials) do
    Ueberauth.Strategy.RingCentral.OAuth.logout(credentials)
  end

  @spec refresh_token(Ueberauth.Auth.Credentials.t()) :: Ueberauth.Auth.Credentials.t()
  def refresh_token(old_credentials) do
    old_credentials
    |> ueberauth_to_oauth_token()
    |> Ueberauth.Strategy.RingCentral.OAuth.refresh_token()
    |> credentials()
  end

  defp option(conn, key) do
    Keyword.get(options(conn) || [], key, Keyword.get(default_options(), key))
  end
end
