defmodule CouponMarketplace.Brand do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc false

  @type id :: pos_integer
  @type t :: %Brand{
    id: id,
    name: String.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type brand_params :: %{name: String.t}

  schema "brands" do
    field :name, :string

    timestamps()
  end

  @spec create(brand_params) :: {:ok, t} | {:error, Ecto.Changeset.t}
  def create(brand_params) do
    required_params = [:name]

    %Brand{}
    |> Ecto.Changeset.cast(brand_params, required_params)
    |> Ecto.Changeset.validate_required(required_params)
    |> Repo.insert()
  end
end
