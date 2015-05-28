defmodule PoolRing.Mixfile do
  use Mix.Project

  def project do
    [app: :pool_ring,
     version: "0.1.3",
     elixir: "~> 1.0",
     description: "create a pool based on a hash ring",
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger],
     mod:          {PoolRing, []}]
  end

  defp deps do
    []
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     contributors: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/camshaft/pool_ring"}]
  end
end
