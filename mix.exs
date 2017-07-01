defmodule CouponMarketplace.Umbrella.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      dialyzer: [plt_add_deps: :transitive],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.8.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5.0", only: [:dev]}
    ]
  end
end
