defmodule CouponMarketplace.Repo.Migrations.CreateCouponsTable do
  use Ecto.Migration

  @moduledoc false

  def change do
    create table(:coupons) do
      add :value, :integer
      add :unique_coupon_code, :string
      add :brand_id, references(:brands)

      timestamps()
    end

    create unique_index(:coupons, [:unique_coupon_code])
    create constraint(:coupons, :value_must_be_positive, check: "value > 0")
  end
end
