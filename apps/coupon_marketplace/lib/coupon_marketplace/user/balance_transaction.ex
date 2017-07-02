defmodule CouponMarketplace.User.BalanceTransaction do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc false

  @type id :: pos_integer
  @type t :: %BalanceTransaction{
    id: id | nil,
    amount: integer | nil,
    user_id: User.id | nil,
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  schema "balance_transactions" do
    field :amount, :integer

    belongs_to :user, User

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(balance_transaction, balance_transaction_params) do
    required_params = [:amount, :user_id]

    balance_transaction
    |> Ecto.Changeset.cast(balance_transaction_params, required_params)
    |> Ecto.Changeset.validate_required(required_params)
  end
end
