defmodule Ueberauth.Strategy.RingCentral.OAuth do
  @moduledoc """
  An implementation of OAuth2 for ring_central.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.RingCentral.OAuth,
        client_id: System.get_env("RING_CENTRAL_CLIENT_ID"),
        client_secret: System.get_env("RING_CENTRAL_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "http://localhost:8080",
    authorize_url: "http://localhost:8080/auth/realms/master/protocol/openid-connect/auth",
    token_url: "http://localhost:8080/auth/realms/master/protocol/openid-connect/token",
    userinfo_url: "http://localhost:8080/auth/realms/master/protocol/openid-connect/userinfo",
    logout_url: "http://localhost:8080/auth/realms/master/protocol/openid-connect/logout",
    token_method: :post
  ]

  @doc """
  Construct a client for requests to RingCentral.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.RingCentral.OAuth.client(redirect_uri: "http://localhost:4000/auth/ring_central/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.RingCentral`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    client_opts =
      @defaults
      |> Keyword.merge(config())
      |> Keyword.merge(opts)

    OAuth2.Client.new(client_opts)
  end

  defp config() do
    # Fetches configuration for `Ueberauth.Strategy.RingCentral.OAuth` Strategy from `config.exs`
    # Also checks if at least `client_id` and `client_secret` are set, raising an error if not.

    :ueberauth
    |> Application.fetch_env!(Ueberauth.Strategy.RingCentral.OAuth)
    |> check_config_key_exists(:client_id)
    |> check_config_key_exists(:client_secret)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  @doc """
  Fetches `userinfo_url` for `Ueberauth.Strategy.RingCentral.OAuth` Strategy from `config.exs`.
  It will be used to get user profile information after an successful authentication.
  """
  def userinfo_url() do
    config()
    |> Keyword.get(:userinfo_url)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("access_token", token)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def logout(credentials, headers \\ [], opts \\ []) do
    logout_url = config() |> Keyword.get(:logout_url)
    body = %{
      client_id: client().client_id,
      client_secret: client().client_secret,
      refresh_token: credentials.refresh_token
    }

    [token: credentials.token]
    |> client
    |> put_header("Content-Type", "application/x-www-form-urlencoded")
    |> post(logout_url, body, headers, opts)
  end

  # def refresh_token(token, params \\ [], headers \\ [], options \\ []) do
  # # This has the same behaviour as below but is more opaque. Left commented
  # # Until it can be understood why the new tokens are still expiring early.
  #   [token: token]
  #   |> client()
  #   |> OAuth2.Client.refresh_token!(params, headers, options)
  #   |> Map.get(:token)
  # end

  def refresh_token(credentials, headers \\ [], opts \\ []) do
    token_url = config() |> Keyword.get(:token_url)
    client = client()
    body = %{
      client_id: client.client_id,
      client_secret: client.client_secret,
      refresh_token: credentials.refresh_token,
      grant_type: "refresh_token"
    }

    client
    |> put_header("Content-Type", "application/x-www-form-urlencoded")
    |> post(token_url, body, headers, opts)
    |> (fn {:ok, %OAuth2.Response{body: body}} -> body end).()
    |> OAuth2.AccessToken.new()
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    client
    |> put_param("response_type", "code")
    |> put_param("redirect_uri", client().redirect_uri)

    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_id", client().client_id)
    |> put_param("client_secret", client().client_secret)
    |> put_param("grant_type", "authorization_code")
    |> put_param("client_session_state", Keyword.get(params, :session_state))
    |> put_param("redirect_uri", client().redirect_uri)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.RingCentral"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.RingCentral is not a keyword list, as expected"
  end
end
