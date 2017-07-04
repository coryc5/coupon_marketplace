defmodule CouponMarketplace.User do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  require Ecto.Query

  @moduledoc """
  User interface API. Users must have unique emails.
  """

  @type id :: pos_integer
  @type t :: %User{
    id: id | nil,
    name: String.t | nil,
    email: String.t | nil,
    initial_deposit: boolean,
    balance: non_neg_integer,
    lock_version: pos_integer,
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  schema "users" do
    field :name, :string
    field :email, :string
    field :initial_deposit, :boolean, default: false
    field :balance, :integer, default: 0
    field :lock_version, :integer, default: 1

    has_many :posts, Transaction, foreign_key: :poster_id
    has_many :requests, Transaction, foreign_key: :requester_id

    timestamps()
  end

  @spec create(map) :: {:ok, t} | {:error, Ecto.Changeset.t}
  def create(user_params) do
    # user can only make initial deposit after creation
    standard_user_params = Map.merge(user_params, %{initial_deposit: false})

    %User{}
    |> changeset(standard_user_params)
    |> Repo.insert()
  end

  @spec find(id) :: {:ok, t} | {:error, :not_found | :bad_request}
  def find(user_id) when not is_integer(user_id), do: {:error, :bad_request}
  def find(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, :not_found}
      %User{} = user -> {:ok, user}
    end
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(user, user_params) do
    required_params = [:name, :email, :initial_deposit]
    balance_check_constraint_opts = [
      name: :balance_must_not_be_negative,
      message: "is less than 0"
    ]

    user
    |> Ecto.Changeset.cast(user_params, required_params)
    |> Ecto.Changeset.validate_required(required_params)
    |> Ecto.Changeset.unique_constraint(:email)
    |> Ecto.Changeset.check_constraint(:balance, balance_check_constraint_opts)
  end

  @spec add_initial_deposit(t) :: {:ok, t} | {:error, Ecto.Changeset.t}
  def add_initial_deposit(%User{initial_deposit: true} = user) do
    changeset =
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.add_error(:initial_deposit, "already exists")

    {:error, changeset}
  end

  def add_initial_deposit(user) do
    user
    |> Ecto.Changeset.change(%{initial_deposit: true, balance: 2000})
    |> Ecto.Changeset.optimistic_lock(:lock_version)
    |> Repo.update()
  end

  @spec query_one(t) :: Ecto.Queryable.t
  def query_one(%User{id: user_id}) do
    Ecto.Query.from(u in User, where: u.id == ^user_id)
  end
end
