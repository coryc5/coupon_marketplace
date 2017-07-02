defmodule CouponMarketplace.Repo.Migrations.CreateBalanceTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:balance_transactions) do
      add :amount, :integer
      add :user_id, references(:users)

      timestamps()
    end
  end
end
