defmodule Islands.Game.MixProject do
  use Mix.Project

  def project do
    [
      app: :islands_game,
      version: "0.1.41",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      name: "Islands Game",
      source_url: source_url(),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp source_url do
    "https://github.com/RaymondLoranger/islands_game"
  end

  defp description do
    """
    A game struct and functions for the Game of Islands.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "config/persist*.exs"],
      maintainers: ["Raymond Loranger"],
      licenses: ["MIT"],
      links: %{"GitHub" => source_url()}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:crypto, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:islands_board, "~> 0.1"},
      {:islands_coord, "~> 0.1"},
      {:islands_guesses, "~> 0.1"},
      {:islands_player, "~> 0.1"},
      {:islands_player_id, "~> 0.1"},
      {:islands_request, "~> 0.1"},
      {:islands_response, "~> 0.1"},
      {:islands_state, "~> 0.1"},
      {:jason, "~> 1.0"},
      {:persist_config, "~> 0.4", runtime: false}
    ]
  end
end
