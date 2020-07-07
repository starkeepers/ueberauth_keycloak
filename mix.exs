defmodule UeberauthRingCentral.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :ueberauth_ring_central_strategy,
      version: @version,
      package: package(),
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/gseddon/ueberauth_ring_central",
      homepage_url: "https://github.com/gseddon/ueberauth_ring_central",
      description: description(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ueberauth, :oauth2]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 0.9"},
      {:ueberauth, "~> 0.6"},
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Ueberauth strategy for using RingCentral to authenticate your users."
  end

  defp package do
    [
      name: "ueberauth_ring_central_strategy",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Gareth S. <gareth.seddon@gmail.com>"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/gseddon/ueberauth_ring_central"}
    ]
  end
end
