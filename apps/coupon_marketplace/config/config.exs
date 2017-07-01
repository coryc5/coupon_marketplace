use Mix.Config

config :coupon_marketplace, ecto_repos: [CouponMarketplace.Repo]

import_config "#{Mix.env}.exs"
