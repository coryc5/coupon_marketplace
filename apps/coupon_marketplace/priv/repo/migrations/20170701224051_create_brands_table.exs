defmodule CouponMarketplace.Repo.Migrations.CreateBrandsTable do
  use Ecto.Migration

  @moduledoc false

  def change do
    create table(:brands) do
      add :name, :string

      timestamps()
    end
  end
end
