defmodule CouponMarketplace.Brand do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc false

  @type id :: pos_integer
  @type t :: %Brand{
    id: id,
    name: String.t,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  schema "brands" do
    field :name, :string

    timestamps()
  end
end
