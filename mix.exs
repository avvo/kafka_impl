defmodule KafkaImpl.Mixfile do
  use Mix.Project

  def project do
    [
      app: :kafka_impl,
      build_embedded: Mix.env == :prod,
      deps: deps(),
      description: description(),
      elixir: "~> 1.4",
      package: package(),
      start_permanent: Mix.env == :prod,
      version: "0.4.4"
    ]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:kafka_ex, "~> 0.6"},

      # NON-PRODUCTION DEPS
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 0.1", only: :dev},
    ]
  end

  defp description do
    """
    A wrapper around KafkaEx so you can mock it in test.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "CHANGELOG.md", "README.md", "LICENSE.txt"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/avvo/kafka_impl",
        "Docs" => "https://hexdocs.pm/kafka_impl"
      },
      maintainers: ["Donald Plummer", "John Fearnside"],
      name: :kafka_impl
    ]
  end
end
