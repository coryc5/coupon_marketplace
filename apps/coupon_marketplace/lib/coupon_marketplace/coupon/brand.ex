defmodule CouponMarketplace.Coupon.Brand do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc false

  @type t :: %Brand{
    id: pos_integer,
    name: String.t,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  schema "brands" do
    field :name, :string

    timestamps()
  end
end
