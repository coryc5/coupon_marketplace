defmodule CouponMarketplace.Repo.Migrations.AddInitialDepositToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :initial_deposit, :boolean
    end
  end
end
