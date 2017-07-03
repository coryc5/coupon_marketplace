defmodule CouponMarketplace.User do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  @moduledoc """
  User interface API. Users must have unique emails.
  """

  @type id :: pos_integer
  @type t :: %User{
    id: id | nil,
    name: String.t | nil,
    email: String.t | nil,
    initial_deposit: boolean,
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  schema "users" do
    field :name, :string
    field :email, :string
    field :initial_deposit, :boolean, default: false

    has_many :balance_transactions, BalanceTransaction

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

  @spec update(t, map) :: {:ok, t} | {:error, Ecto.Changeset.t}
  def update(user, user_params) do
    user
    |> changeset(user_params)
    |> Repo.update()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(user, user_params) do
    required_params = [:name, :email, :initial_deposit]

    user
    |> Ecto.Changeset.cast(user_params, required_params)
    |> Ecto.Changeset.validate_required(required_params)
    |> Ecto.Changeset.unique_constraint(:email)
  end

  @spec create_balance_transaction(t, integer) ::
    {:ok, BalanceTransaction.t} | {:error, Ecto.Changeset.t}
  def create_balance_transaction(user, amount) do
    user
    |> Ecto.build_assoc(:balance_transactions)
    |> BalanceTransaction.changeset(%{amount: amount})
    |> Repo.insert()
  end

  @spec maybe_add_initial_deposit(t) :: {:ok, t} | {:error, Ecto.Changeset.t}
  def maybe_add_initial_deposit(%User{initial_deposit: false} = user),
    do: add_initial_deposit(user)
  def maybe_add_initial_deposit(%User{initial_deposit: true} = user) do
    changeset =
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.add_error(:initial_deposit, "already exists")

    {:error, changeset}
  end

  @spec get_balance(t) :: non_neg_integer | nil
  def get_balance(user) do
    user
    |> Ecto.assoc(:balance_transactions)
    |> Repo.aggregate(:sum, :amount)
  end

  @spec add_initial_deposit(t) :: {:ok, t} | {:error, Ecto.Changeset.t}
  defp add_initial_deposit(user) do
    with {:ok, _balance_transaction} <- create_balance_transaction(user, 2000),
      do: update(user, %{initial_deposit: true})
  end
end
