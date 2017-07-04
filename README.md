# CouponMarketplace.Umbrella

## Instructions
  * Navigate to CouponMarketplace with `cd apps/coupon_marketplace`
  * Install dependencies with `mix deps.get`
  * Setup ecto and run seeds script with `mix ecto.setup`
  * Start application with `iex -S mix`

  * Reset database and rerun seeds script `mix ecto.reset`

  * From the root of the umbrella project:
  * Install dependencies with `mix deps.get`
  * Run tests with `mix coveralls`
  * Lint with `mix credo`
  * Run static analysis with `mix dialyzer` (warning, initial run requires substantial time to build PLT)

## Design
  An umbrella project with a core API that is meant to be a dependency to other
  client interfaces, for instance a Phoenix application. All functions are
  written to be run within a user's process which allow for concurrency. In a
  Phoenix app, this concurrency is built-in as each connection runs in its own
  process via Cowboy.

  Certain functions, such as posting a new coupon or requesting a coupon that is
  already posted, have their concurrency restricted at the database level, in
  this case, Postgres via Ecto.

## Other notes
  Besides Ecto, this project also uses external dependencies for coverage
  ([excoveralls](https://hex.pm/packages/excoveralls)), styling ([credo](https://hex.pm/packages/credo)) and static analysis ([dialyxir](https://hex.pm/packages/dialyxir)).
