defmodule CouponMarketplace.Repo.Migrations.CreateTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :coupon_id, references(:coupons)
      add :poster_id, references(:users)
      add :requester_id, references(:users)

      timestamps()
    end
  end
end
