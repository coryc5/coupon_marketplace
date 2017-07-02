defmodule CouponMarketplace.Coupon do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc """
  Coupon interface API. A coupon's value is stored as an integer in cents.
  """

  @type id :: pos_integer
  @type t :: %Coupon{
    id: id,
    value: pos_integer,
    unique_coupon_code: String.t,
    brand_id: Brand.id,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  schema "coupons" do
    field :value, :integer
    field :unique_coupon_code, :string

    belongs_to :brand, Brand

    timestamps()
  end
end
