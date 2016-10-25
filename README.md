# KafkaImpl

A wrapper around KafkaEx so you can mock it in test.

## Installation

[Available in Hex](https://hex.pm/packages/kafka_impl), the package can be installed as:

  1. Add `kafka_impl` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:kafka_impl, "~> 0.1.0"}]
    end
    ```

  2. Ensure `kafka_impl` is started before your application:

    ```elixir
    def application do
      [applications: [:kafka_impl]]
    end
    ```

