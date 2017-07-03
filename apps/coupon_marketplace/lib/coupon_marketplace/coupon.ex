defmodule CouponMarketplace.Coupon do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc """
  Coupon interface API. A coupon's value is stored as an integer in cents.
  """

  @type id :: pos_integer
  @type changeset :: Ecto.Changeset.t
  @type t :: %Coupon{
    id: id | nil,
    value: pos_integer | nil,
    unique_coupon_code: String.t | nil,
    brand_id: Brand.id | nil,
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  schema "coupons" do
    field :value, :integer
    field :unique_coupon_code, :string

    belongs_to :brand, Brand

    has_many :transactions, Transaction

    timestamps()
  end

  @spec new(Brand.t) :: t
  def new(brand) do
    Ecto.build_assoc(brand, :coupons)
  end

  @spec find(id) :: {:ok, t} | {:error, :not_found | :bad_request}
  def find(coupon_id) when not is_integer(coupon_id), do: {:error, :bad_request}
  def find(coupon_id) do
    case Repo.get(Coupon, coupon_id) do
      nil -> {:error, :not_found}
      %Coupon{} = coupon -> {:ok, coupon}
    end
  end

  @spec changeset(t, map) :: changeset
  def changeset(coupon, coupon_params = %{brand: brand}) do
    required_params = [:value, :unique_coupon_code]
    value_check_constraint_opts = [
      name: :value_must_be_positive,
      message: "is not greater than 0"
    ]

    coupon
    |> Ecto.Changeset.cast(coupon_params, required_params)
    |> Ecto.Changeset.validate_required(required_params)
    |> Ecto.Changeset.put_assoc(:brand, brand, required: true)
    |> Ecto.Changeset.check_constraint(:value, value_check_constraint_opts)
    |> Ecto.Changeset.unique_constraint(:unique_coupon_code)
  end
end
