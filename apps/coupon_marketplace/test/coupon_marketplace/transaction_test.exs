defmodule CouponMarketplace.TransactionTest do
  use CouponMarketplace.DataCase, async: true

  setup do
    {:ok, brand} = Brand.create(%{name: "test brand #{:rand.uniform}"})

    {:ok, user_a} = User.create(%{
      name: "test user a",
      email: "test_a@email.com"
    })
    {:ok, user_a} = User.add_initial_deposit(user_a)

    {:ok, coupon} = Coupon.create(%{
      value: 500,
      unique_coupon_code: Ecto.UUID.generate(),
    }, user_a, brand)

    {:ok, user_b} = User.create(%{
      name: "test user b",
      email: "test_b@email.com"
    })
    {:ok, user_b} = User.add_initial_deposit(user_b)

    {:ok, coupon: coupon, user_a: user_a, user_b: user_b}
  end


  test "maybe_post creates new transaction when valid", %{coupon: coupon, user_a: user_a} do
    {:ok, transaction} = Transaction.maybe_post(coupon, user_a)

    {:ok, coupon} = Coupon.find(transaction.coupon_id)
    assert coupon.open_transaction_id == transaction.id

    {:ok, result_transaction} = Transaction.find(transaction.id)
    assert result_transaction.poster_id == user_a.id
    assert result_transaction.requester_id == nil
  end

  test "poster cannot post existing posting", %{coupon: coupon, user_a: user_a} do
    {:ok, transaction} = Transaction.maybe_post(coupon, user_a)
    assert_raise(Ecto.StaleEntryError, fn ->
      Transaction.maybe_post(coupon, user_a)
    end)

    {:ok, coupon} = Coupon.find(transaction.coupon_id)
    assert {:error, :invalid_post} == Transaction.maybe_post(coupon, user_a)

    total_transactions =
      Transaction
      |> Repo.all()
      |> Enum.count(fn(transaction) ->
        transaction.coupon_id == coupon.id
      end)

    assert total_transactions == 1
  end

  test "maybe_request updates transaction when valid", %{coupon: coupon, user_a: user_a, user_b: user_b} do
    {:ok, _posting} = Transaction.maybe_post(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)
    {:ok, %{request: transaction}} = Transaction.maybe_request(coupon, user_b)

    {:ok, result_transaction} = Transaction.find(transaction.id)
    {:ok, result_user_a} = User.find(user_a.id)
    {:ok, result_user_b} = User.find(user_b.id)

    assert result_transaction.poster_id == user_a.id
    assert result_transaction.requester_id == user_b.id
    assert result_user_a.balance == 2000 + coupon.value - result_transaction.marketplace_share
    assert result_user_b.balance == 2000 - coupon.value
  end

  test "poster cannot request their own posting", %{coupon: coupon, user_a: user_a} do
    {:ok, transaction} = Transaction.maybe_post(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)

    assert {:error, :owner_cannot_request_coupon} = Transaction.maybe_request(coupon, user_a)

    {:ok, result_transaction} = Transaction.find(transaction.id)
    assert result_transaction.requester_id == nil

    {:ok, result_user_a} = User.find(user_a.id)
    assert result_user_a.balance == 2000
  end

  test "same posting cannot be requested twice", %{coupon: coupon, user_a: user_a, user_b: user_b} do
    {:ok, _transaction} = Transaction.maybe_post(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)

    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)

    # stale coupon indicating open transaction
    assert {:error, :invalid_request} == Transaction.maybe_request(coupon, user_b)

    # coupon after transaction closes
    {:ok, coupon} = Coupon.find(coupon.id)
    assert {:error, :coupon_not_posted} == Transaction.maybe_request(coupon, user_b)
  end

  test "requester can only request after initial deposit", %{coupon: coupon, user_a: user_a, user_b: user_b} do
    {:ok, _transaction} = Transaction.maybe_post(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)

    assert {:error, :user_has_not_made_initial_deposit} == Transaction.maybe_request(coupon, %User{user_b | initial_deposit: false})
  end

  test "requester can only request when their balance is atleast equal to coupon value", %{coupon: coupon, user_a: user_a, user_b: user_b} do
    {:ok, _transaction} = Transaction.maybe_post(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)

    assert {:error, :balance_too_low} == Transaction.maybe_request(coupon, %User{user_b | balance: 0})
  end

  test "second posting can also be requested", %{coupon: coupon, user_a: user_a, user_b: user_b} do
    {:ok, _transaction} = Transaction.maybe_post(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)
    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)
    {:ok, coupon} = Coupon.find(coupon.id)
    assert coupon.owner_id == user_b.id

    {:ok, _third_transaction} = Transaction.maybe_post(coupon, user_b)
    {:ok, coupon} = Coupon.find(coupon.id)
    {:ok, fourth_transaction} = Transaction.maybe_request(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)
    assert coupon.owner_id == user_a.id

    {:ok, result_transaction} = Transaction.find(fourth_transaction.request.id)

    assert result_transaction.poster_id == user_b.id
    assert result_transaction.requester_id == user_a.id
  end

  test "poster cannot post coupon they don't own", %{coupon: coupon, user_a: user_a, user_b: user_b} do
    {:ok, _transaction} = Transaction.maybe_post(coupon, user_a)
    {:ok, coupon} = Coupon.find(coupon.id)
    {:ok, _second_transaction} = Transaction.maybe_request(coupon, user_b)

    assert {:error, :invalid_post} == Transaction.maybe_post(coupon, user_a)
  end
end
