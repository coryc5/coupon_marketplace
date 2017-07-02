defmodule CouponMarketplace.Repo.Migrations.CreateCouponTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:coupon_transactions) do
      add :coupon_id, references(:coupons)
      add :poster_id, references(:users)
      add :requester_id, references(:users)

      timestamps()
    end
  end
end
