defmodule CouponMarketplace.TransactionTest do
  use CouponMarketplace.DataCase, async: true

  setup do
    {:ok, brand} = Brand.create(%{name: "test brand"})

    coupon_params = %{
      value: 500,
      unique_coupon_code: Ecto.UUID.generate(),
      brand: brand
    }

    {:ok, user_a} = User.create(%{
      name: "test user a",
      email: "test_a@email.com"
    })

    {:ok, user_b} = User.create(%{
      name: "test user b",
      email: "test_b@email.com"
    })

    User.add_initial_deposit(user_a)
    User.add_initial_deposit(user_b)

    {:ok, transaction_params: %{coupon: coupon_params}, user_a: user_a, user_b: user_b}
  end

  test "create_from_new_coupon creates transaction and coupon", %{transaction_params: transaction_params, user_a: user} do
    {:ok, %Transaction{
      id: transaction_id,
      coupon_id: coupon_id
    }} = Transaction.create_from_new_coupon(transaction_params, user)

    {:ok, result_transaction} = Transaction.find(transaction_id)
    {:ok, result_coupon} = Coupon.find(coupon_id)

    assert result_transaction.poster_id == user.id
    assert result_coupon.unique_coupon_code == transaction_params.coupon.unique_coupon_code
  end

  test "create_from_new_coupon cannot create from same coupon twice", %{transaction_params: transaction_params, user_a: user} do
    {:ok, transaction} = Transaction.create_from_new_coupon(transaction_params, user)
    {:error, changeset} = Transaction.create_from_new_coupon(transaction_params, user)
    transactions_with_unique_coupon_code =
      Transaction
      |> Repo.all()
      |> Repo.preload(:coupon)
      |> Stream.map(fn(%Transaction{coupon: coupon}) -> coupon end)
      |> Enum.count(fn(coupon) ->
        coupon.unique_coupon_code == transaction.coupon.unique_coupon_code
      end)

    refute changeset.valid?
    assert transactions_with_unique_coupon_code == 1
  end

  test "maybe_request updates transaction when valid", %{transaction_params: transaction_params, user_a: user_a, user_b: user_b} do
    {:ok, first_transaction} = Transaction.create_from_new_coupon(transaction_params, user_a)
    {:ok, coupon} = Coupon.find(first_transaction.coupon_id)

    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)

    {:ok, result_transaction} = Transaction.find(first_transaction.id)
    {:ok, result_user_a} = User.find(user_a.id)
    {:ok, result_user_b} = User.find(user_b.id)

    assert result_transaction.poster_id == user_a.id
    assert result_transaction.requester_id == user_b.id
    assert result_user_a.balance == 2000 + coupon.value - result_transaction.marketplace_share
    assert result_user_b.balance == 2000 - coupon.value
  end

  test "poster cannot request their own posting", %{transaction_params: transaction_params, user_a: user_a} do
    {:ok, transaction} = Transaction.create_from_new_coupon(transaction_params, user_a)
    {:ok, coupon} = Coupon.find(transaction.coupon_id)

    assert {:error, :invalid_request} = Transaction.maybe_request(coupon, user_a)

    {:ok, result_transaction} = Transaction.find(transaction.id)
    assert result_transaction.requester_id == nil

    {:ok, result_user_a} = User.find(user_a.id)
    assert result_user_a.balance == 2000
  end

  test "same posting cannot be requested twice", %{transaction_params: transaction_params, user_a: user_a, user_b: user_b} do
    {:ok, first_transaction} = Transaction.create_from_new_coupon(transaction_params, user_a)
    {:ok, coupon} = Coupon.find(first_transaction.coupon_id)

    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)

    assert {:error, :invalid_request} == Transaction.maybe_request(coupon, user_b)
  end

  test "maybe_post creates new transaction when valid", %{transaction_params: transaction_params, user_a: user_a, user_b: user_b} do
    {:ok, first_transaction} = Transaction.create_from_new_coupon(transaction_params, user_a)
    {:ok, coupon} = Coupon.find(first_transaction.coupon_id)
    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)

    {:ok, result_transaction} = Transaction.maybe_post(coupon, user_b)

    assert result_transaction.poster_id == user_b.id
  end

  test "second posting can also be requested", %{transaction_params: transaction_params, user_a: user_a, user_b: user_b} do
    {:ok, first_transaction} = Transaction.create_from_new_coupon(transaction_params, user_a)
    {:ok, coupon} = Coupon.find(first_transaction.coupon_id)
    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)
    {:ok, _third_transaction} = Transaction.maybe_post(coupon, user_b)
    {:ok, fourth_transaction} = Transaction.maybe_request(coupon, user_a)
    {:ok, result_transaction} = Transaction.find(fourth_transaction.request.id)

    assert result_transaction.poster_id == user_b.id
    assert result_transaction.requester_id == user_a.id
  end

  test "poster cannot post existing posting", %{transaction_params: transaction_params, user_a: user_a} do
    {:ok, first_transaction} = Transaction.create_from_new_coupon(transaction_params, user_a)
    {:ok, coupon} = Coupon.find(first_transaction.coupon_id)

    assert {:error, :invalid_post} == Transaction.maybe_post(coupon, user_a)
  end

  test "poster cannot post coupon they don't own", %{transaction_params: transaction_params, user_a: user_a, user_b: user_b} do
    {:ok, first_transaction} = Transaction.create_from_new_coupon(transaction_params, user_a)
    {:ok, coupon} = Coupon.find(first_transaction.coupon_id)
    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)

    assert {:error, :invalid_post} == Transaction.maybe_post(coupon, user_a)
  end
end
