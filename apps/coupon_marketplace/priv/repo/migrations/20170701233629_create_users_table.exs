defmodule CouponMarketplace.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :balance, :integer
      add :lock_version, :integer

      timestamps()
    end

    create unique_index(:users, [:email])
    create constraint(:users, :balance_must_not_be_negative, check: "balance >= 0")
  end
end
