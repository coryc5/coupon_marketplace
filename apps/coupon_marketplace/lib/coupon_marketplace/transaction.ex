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
    inserted_at: NaiveDateTime.t | nil,
    updated_at: NaiveDateTime.t | nil
  }

  schema "transactions" do
    belongs_to :coupon, Coupon
    belongs_to :poster, User
    belongs_to :requester, User

    timestamps()
  end

  @spec create_from_new_coupon(map, User.t) ::
    {:ok, t} | {:error, changeset}
  def create_from_new_coupon(transaction_params, poster) do
    %Transaction{}
    |> Ecto.Changeset.cast(transaction_params, [])
    |> Ecto.Changeset.put_assoc(:poster, poster, required: true)
    |> Ecto.Changeset.cast_assoc(:coupon, required: true)
    |> Repo.insert()
  end

  @spec maybe_post(Coupon.t, User.t) :: {:ok, t} | {:error, changeset | atom}
  def maybe_post(coupon, poster = %User{id: poster_id}) do
    last_transaction =
      coupon
      |> last_transaction_for_coupon()
      |> Repo.one()

    case last_transaction do
      %{requester_id: ^poster_id} -> post(coupon, poster)
      %{requester_id: _} -> {:error, :invalid_post}
      nil -> {:error, :not_found}
    end
  end

  @spec maybe_request(Coupon.t, User.t) :: {:ok, t} | {:error, changeset | atom}
  def maybe_request(coupon, requester = %User{id: requester_id}) do
    Repo.transaction(fn ->
      last_transaction =
        coupon
        |> last_transaction_for_coupon()
        |> lock("FOR UPDATE")
        |> Repo.one()
        |> Repo.preload(:poster)

      case last_transaction do
        %{poster_id: ^requester_id} ->
          {:error, :invalid_request}
        %{requester_id: nil} ->
          request(last_transaction, coupon, requester)
        %{requester_id: _} ->
          {:error, :invalid_request}
        nil ->
          {:error, :not_found}
      end
    end)
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

  def last_transaction_for_coupon(%Coupon{id: coupon_id}) do
    query = from t in Transaction,
      where: t.coupon_id == ^coupon_id

    last(query, :inserted_at)
  end

  defp post(coupon, poster) do
    %Transaction{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:poster, poster, required: true)
    |> Ecto.Changeset.put_assoc(:coupon, coupon, required: true)
    |> Repo.insert()
  end

  defp request(transaction, %Coupon{value: coupon_value}, requester) do
    marketplace_share = round(coupon_value * 0.05)
    poster_credit = coupon_value - marketplace_share

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:debit_requester, requester, inc: [balance: -coupon_value])
    |> Ecto.Multi.update_all(:credit_poster, transaction.poster, inc: [balance: poster_credit])
    |> Ecto.Multi.update(:request, request_changeset(transaction, requester, marketplace_share))
  end

  defp request_changeset(transaction, requester, marketplace_share) do
    required_params = [:marketplace_share]

    transaction
    |> Ecto.Changeset.cast(%{marketplace_share: marketplace_share}, required_params)
    |> Ecto.Changeset.put_assoc(:requester, requester, required: true)
  end
end