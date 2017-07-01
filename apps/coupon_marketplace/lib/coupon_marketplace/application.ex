defmodule CouponMarketplace.Application do
  @moduledoc """
  The CouponMarketplace Application Service.

  The coupon_marketplace system business domain lives in this application.

  Exposes API to clients such as the `CouponMarketplace.Web` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link([
      worker(CouponMarketplace.Repo, []),
    ], strategy: :one_for_one, name: CouponMarketplace.Supervisor)
  end
end
