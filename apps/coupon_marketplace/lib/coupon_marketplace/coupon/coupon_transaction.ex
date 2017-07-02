defmodule CouponMarketplace.Coupon.CouponTransaction do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc false

  @type id :: pos_integer
  @type t :: %CouponTransaction{
    id: id,
    coupon_id: Coupon.id,
    poster_id: User.id,
    requester_id: User.id,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  schema "coupon_transactions" do
    belongs_to :coupon, Coupon
    belongs_to :poster, User
    belongs_to :requester, User

    timestamps()
  end
end
