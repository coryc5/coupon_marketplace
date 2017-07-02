defmodule CouponMarketplace.User do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc """
  User interface API. Users must have unique emails.
  """

  @type id :: pos_integer
  @type t :: %User{
    id: id,
    name: String.t,
    email: String.t,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  schema "users" do
    field :name, :string
    field :email, :string

    timestamps()
  end
end
