defmodule CouponMarketplace.User.BalanceTransaction do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc false

  @type id :: pos_integer
  @type t :: %BalanceTransaction{
    id: id,
    amount: integer,
    user_id: User.id,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  schema "balance_transactions" do
    field :amount, :integer

    belongs_to :user, User

    timestamps()
  end
end
