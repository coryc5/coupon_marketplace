defmodule CouponMarketplace.Coupon.CouponPosting do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc false

  @type id :: pos_integer
  @type t :: %CouponPosting{
    id: id,
    coupon_id: Coupon.id,
    poster_id: User.id,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  schema "coupon_postings" do
    belongs_to :coupon, Coupon
    belongs_to :poster, User

    timestamps()
  end
end
