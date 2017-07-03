defmodule CouponMarketplace.TransactionTest do
  use CouponMarketplace.DataCase, async: true

  setup do
    {:ok, brand} = Brand.create(%{name: "test brand"})

    coupon_params = %{
      value: 500,
      unique_coupon_code: Ecto.UUID.generate(),
      brand: brand
    }

    {:ok, user} = User.create(%{
      name: "test user",
      email: "test@email.com"
    })

    {:ok, transaction_params: %{coupon: coupon_params}, user: user}
  end

  test "create_from_new_coupon creates transaction and coupon", %{transaction_params: transaction_params, user: user} do
    {:ok, %Transaction{
      id: transaction_id,
      coupon_id: coupon_id
    }} = Transaction.create_from_new_coupon(transaction_params, user)

    {:ok, result_transaction} = Transaction.find(transaction_id)
    {:ok, result_coupon} = Coupon.find(coupon_id)

    assert result_transaction.poster_id == user.id
    assert result_coupon.unique_coupon_code == transaction_params.coupon.unique_coupon_code
  end

  test "create_from_new_coupon cannot create from same coupon twice", %{transaction_params: transaction_params, user: user} do
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
end
