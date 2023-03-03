defmodule ADDR.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :addr,
      version: "0.11.0",
      elixir: "~> 1.8",
      description: "ADDR Addresses Registry",
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      files: ~w(doc lib priv src mix.exs LICENSE),
      licenses: ["ISC"],
      maintainers: ["Namdak Tonpa"],
      name: :addr,
      links: %{"GitHub" => "https://github.com/erpuno/addr"}
    ]
  end

  def application() do
    [mod: {ADDR, []}]
  end

  def deps() do
    [
      {:kvs,    "~> 9.9.0", runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
