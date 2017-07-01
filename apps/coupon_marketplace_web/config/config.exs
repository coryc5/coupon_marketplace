# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :coupon_marketplace_web,
  namespace: CouponMarketplace.Web,
  ecto_repos: [CouponMarketplace.Repo]

# Configures the endpoint
config :coupon_marketplace_web, CouponMarketplace.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bZ3gRsb7Xd+EW1TT1advD6ha/0+W9zA5SzgK+5XuAihGkooKFJGF8yfctktK6Qz2",
  render_errors: [view: CouponMarketplace.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: CouponMarketplace.Web.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
