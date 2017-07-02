defmodule CouponMarketplace.Aliases do
  @moduledoc """
  For making application aliases available to modules
  """

  defmacro __using__(_) do
    quote do
      alias CouponMarketplace.{
        Brand,
        Coupon,
        Coupon.CouponPosting,
        User,
      }
    end
  end
end
