defmodule CouponMarketplace.Repo.Migrations.AddOpenTransactionIdToCoupons do
  use Ecto.Migration

  def change do
    alter table(:coupons) do
      add :open_transaction_id, references(:transactions)
    end
  end
end
