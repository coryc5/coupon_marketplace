defmodule CouponMarketplace.Repo.Migrations.CreateCouponPostingsTable do
  use Ecto.Migration

  def change do
    create table(:coupon_postings) do
      add :coupon_id, references(:coupons)
      add :poster_id, references(:users)

      timestamps()
    end
  end
end
