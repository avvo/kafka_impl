defmodule KafkaImpl.Mixfile do
  use Mix.Project

  def project do
    [
      app: :kafka_impl,
      build_embedded: Mix.env == :prod,
      deps: deps(),
      description: description(),
      elixir: "~> 1.3",
      package: package(),
      start_permanent: Mix.env == :prod,
      version: "0.2.0",
    ]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:kafka_ex, "~> 0.6.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end

  defp description do
    """
    A wrapper around KafkaEx so you can mock it in test.
    """
  end

  defp package do
    [
      name: :kafka_impl,
      files: ["lib", "mix.exs", "CHANGELOG.md", "README.md", "LICENSE.txt"],
      maintainers: ["Donald Plummer"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/avvo/avrolixr",
               "Docs" => "https://hexdocs.pm/avrolixr"}
    ]
  end
end
