defmodule CouponMarketplace.Transaction do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc """
  Transaction interface.
  """

  @type id :: pos_integer
  @type changeset :: Ecto.Changeset.t
  @type t :: %Transaction{
    id: id | nil,
    coupon_id: Coupon.id | nil,
    poster_id: User.id | nil,
    requester_id: User.id | nil,
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  schema "transactions" do
    belongs_to :coupon, Coupon
    belongs_to :poster, User
    belongs_to :requester, User

    timestamps()
  end

  @spec create_from_new_coupon(map, User.t) ::
    {:ok, t} | {:error, changeset}
  def create_from_new_coupon(transaction_params, user) do
    %Transaction{}
    |> Ecto.Changeset.change(transaction_params)
    |> Ecto.Changeset.put_assoc(:poster, user, required: true)
    |> Ecto.Changeset.cast_assoc(:coupon, required: true)
    |> Repo.insert()
  end
end
