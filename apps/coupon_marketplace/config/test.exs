use Mix.Config

config :coupon_marketplace, CouponMarketplace.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "coupon_marketplace_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
