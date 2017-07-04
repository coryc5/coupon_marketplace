defmodule CouponMarketplace.Transaction do
  use Ecto.Schema
  use CouponMarketplace.Aliases

  import Ecto.Query

  @moduledoc """
  Transaction interface.
  """

  @type id :: pos_integer
  @type changeset :: Ecto.Changeset.t
  @type t :: %Transaction{
    id: id | nil,
    coupon_id: Coupon.id | nil,
    poster_id: User.id | nil,
    requester_id: User.id | nil,
    marketplace_share: non_neg_integer,
    lock_version: pos_integer,
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  schema "transactions" do
    field :marketplace_share, :integer, default: 0
    field :lock_version, :integer, default: 1

    belongs_to :coupon, Coupon
    belongs_to :poster, User
    belongs_to :requester, User

    timestamps()
  end

  @spec find(id) :: {:ok, t} | {:error, :not_found | :bad_request}
  def find(transaction_id) when not is_integer(transaction_id),
    do: {:error, :bad_requset}
  def find(transaction_id) do
    case Repo.get(Transaction, transaction_id) do
      nil -> {:error, :not_found}
      %Transaction{} = transaction -> {:ok, transaction}
    end
  end

  @spec maybe_post(Coupon.t, User.t) :: {:ok, t} | {:error, changeset | atom}
  def maybe_post(%Coupon{open_transaction_id: open_transaction_id}, _poster)
    when not is_nil(open_transaction_id), do: {:error, :invalid_post}
  def maybe_post(coupon, poster) do
    Repo.transaction(fn ->
      transaction =
        %Transaction{}
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:coupon, coupon, required: true)
        |> Ecto.Changeset.put_assoc(:poster, poster, required: true)
        |> Repo.insert!()

      coupon
      |> Repo.preload(:open_transaction)
      |> Coupon.changeset(%{})
      |> Ecto.Changeset.put_assoc(:open_transaction, transaction)
      |> Repo.update!()

      transaction
    end)
  end

  @spec maybe_request(Coupon.t, User.t) :: {:ok, map} | {:error, changeset | atom}
  def maybe_request(_coupon, %User{initial_deposit: false}),
    do: {:error, :user_has_not_made_initial_deposit}
  def maybe_request(%Coupon{open_transaction_id: nil}, _requester),
    do: {:error, :coupon_not_posted}
  def maybe_request(%Coupon{owner_id: requester_id}, %User{id: requester_id}),
    do: {:error, :owner_cannot_request_coupon}
  def maybe_request(%Coupon{value: value}, %User{balance: balance}) when value > balance,
    do: {:error, :balance_too_low}
  def maybe_request(coupon, requester) do
    %Coupon{open_transaction_id: open_transaction_id} = coupon

    case lock_find_for_update(open_transaction_id) do
      nil ->
        {:error, :invalid_request}
      open_transaction ->
        open_transaction
        |> Repo.preload([:poster, :requester])
        |> request(coupon, requester)
        |> Repo.transaction()
    end
  end

  @doc """
  Finds a transaction and adds a row lock until transaction completes or aborts
  """
  @spec lock_find_for_update(id) :: t | nil
  def lock_find_for_update(transaction_id) do
    Transaction
    |> where([t], t.id == ^transaction_id)
    |> where([t], is_nil(t.requester_id))
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  defp request(transaction, %Coupon{value: coupon_value} = coupon, requester) do
    marketplace_share = round(coupon_value * 0.05)
    poster_credit = coupon_value - marketplace_share

    Ecto.Multi.new()
    |> Ecto.Multi.run(:debit_requester, &debit_requester(&1, requester, coupon_value))
    |> Ecto.Multi.update_all(:credit_poster, User.query_one(transaction.poster), inc: [balance: poster_credit])
    |> Ecto.Multi.update(:request, request_changeset(transaction, requester, marketplace_share))
    |> Ecto.Multi.update(:coupon, Coupon.close_transaction(coupon, requester))
  end

  defp debit_requester(_multi, requester, coupon_value) do
    try do
      Repo.update_all(User.query_one(requester), inc: [balance: -coupon_value])
    rescue
      _ -> {:error, :invalid_debit_request}
    else
      _ -> {:ok, requester}
    end
  end

  defp request_changeset(transaction, requester, marketplace_share) do
    required_params = [:marketplace_share]

    transaction
    |> Ecto.Changeset.cast(%{marketplace_share: marketplace_share}, required_params)
    |> Ecto.Changeset.put_assoc(:requester, requester, required: true)
  end
end
