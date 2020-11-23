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
      files: ~w(doc priv src mix.exs LICENSE),
      licenses: ["ISC"],
      maintainers: ["Namdak Tonpa"],
      name: :addr,
      links: %{"GitHub" => "https://github.com/erpuno/addr"}
    ]
  end

  def application() do
    [mod: {:addr, []}]
  end

  def deps() do
    [
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end
