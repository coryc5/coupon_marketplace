defmodule CouponMarketplace.Coupon do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc """
  Coupon interface. A coupon's value is stored as an integer in cents.
  """

  @type id :: pos_integer
  @type changeset :: Ecto.Changeset.t
  @type t :: %Coupon{
    id: id | nil,
    value: pos_integer | nil,
    unique_coupon_code: String.t | nil,
    lock_version: pos_integer,
    brand_id: Brand.id | nil,
    owner_id: User.id,
    open_transaction_id: Transaction.id | nil,
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  @required_params [:value, :unique_coupon_code, :lock_version]

  schema "coupons" do
    field :value, :integer
    field :unique_coupon_code, :string
    field :lock_version, :integer, default: 1

    belongs_to :brand, Brand
    belongs_to :owner, User
    belongs_to :open_transaction, Transaction

    has_many :transactions, Transaction

    timestamps()
  end

  @spec create(map, User.t, Brand.t) :: {:ok, t} | {:error, changeset | atom}
  def create(_coupon_params, %User{initial_deposit: false}, _brand),
    do: {:error, :user_has_not_made_initial_deposit}
  def create(coupon_params, owner, brand) do
    %Coupon{}
    |> changeset(coupon_params)
    |> Ecto.Changeset.validate_required(@required_params)
    |> Ecto.Changeset.put_assoc(:owner, owner, required: true)
    |> Ecto.Changeset.put_assoc(:brand, brand, required: true)
    |> Repo.insert()
  end

  @spec find(id) :: {:ok, t} | {:error, :not_found | :bad_request}
  def find(coupon_id) when not is_integer(coupon_id),
    do: {:error, :bad_request}
  def find(coupon_id) do
    case Repo.get(Coupon, coupon_id) do
      nil -> {:error, :not_found}
      %Coupon{} = coupon -> {:ok, coupon}
    end
  end

  @spec changeset(t, map) :: changeset
  def changeset(coupon, coupon_params) do
    value_check_constraint_opts = [
      name: :value_must_be_positive,
      message: "is not greater than 0"
    ]

    coupon
    |> Ecto.Changeset.cast(coupon_params, @required_params)
    |> Ecto.Changeset.optimistic_lock(:lock_version)
    |> Ecto.Changeset.check_constraint(:value, value_check_constraint_opts)
    |> Ecto.Changeset.unique_constraint(:unique_coupon_code)
  end

  @spec close_transaction(t, User.t) :: changeset
  def close_transaction(coupon, new_owner) do
    coupon
    |> changeset(%{})
    |> Ecto.Changeset.change(%{owner_id: nil, open_transaction_id: nil})
  end
end
