defmodule Goodies.MixProject do
  use Mix.Project

  def project do
    [
      app: :goodies,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_options: [warnings_as_errors: true],
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:conduit, "~> 0.12"},
      {:tesla, "~> 1.3"},
      {:credo, "~> 1.4.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp aliases, do: [test: ["test", "credo --strict"]]
end
