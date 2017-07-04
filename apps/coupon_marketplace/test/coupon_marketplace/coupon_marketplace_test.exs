defmodule CouponMarketplaceTest do
  use CouponMarketplace.DataCase, async: true

  test "users" do
    assert CouponMarketplace.users() == []

    {:ok, a} = User.create(%{name: "test user a", email: "test_a@email.com"})
    {:ok, b} = User.create(%{name: "test user b", email: "test_b@email.com"})
    {:ok, c} = User.create(%{name: "test user c", email: "test_c@email.com"})

    assert Enum.member?(CouponMarketplace.users(), a)
    assert Enum.member?(CouponMarketplace.users(), b)
    assert Enum.member?(CouponMarketplace.users(), c)
    assert length(CouponMarketplace.users()) == 3
  end

  test "transactions" do
    assert CouponMarketplace.transactions() == []

    {:ok, a} = User.create(%{name: "test user a", email: "test_a@email.com"})
    {:ok, a} = User.add_initial_deposit(a)
    {:ok, b} = User.create(%{name: "test user b", email: "test_b@email.com"})
    {:ok, b} = User.add_initial_deposit(b)
    {:ok, c} = User.create(%{name: "test user c", email: "test_c@email.com"})
    {:ok, c} = User.add_initial_deposit(c)

    {:ok, brand} = Brand.create(%{name: "test brand #{:rand.uniform}"})
    {:ok, coupon_a} = Coupon.create(%{
      value: 500,
      unique_coupon_code: Ecto.UUID.generate(),
    }, a, brand)
    {:ok, coupon_b} = Coupon.create(%{
      value: 200,
      unique_coupon_code: Ecto.UUID.generate(),
    }, b, brand)
    {:ok, coupon_c} = Coupon.create(%{
      value: 700,
      unique_coupon_code: Ecto.UUID.generate(),
    }, c, brand)

    {:ok, transaction_a} = Transaction.maybe_post(coupon_a, a)
    {:ok, transaction_b} = Transaction.maybe_post(coupon_b, b)
    {:ok, transaction_c} = Transaction.maybe_post(coupon_c, c)

    transactions_ids = CouponMarketplace.transactions() |> Enum.map(& Map.get(&1, :id))

    assert length(transactions_ids) == 3
    assert Enum.member?(transactions_ids, transaction_a.id)
    assert Enum.member?(transactions_ids, transaction_b.id)
    assert Enum.member?(transactions_ids, transaction_c.id)
  end

  test "revenue" do
    {:ok, a} = User.create(%{name: "test user a", email: "test_a@email.com"})
    {:ok, a} = User.add_initial_deposit(a)
    {:ok, b} = User.create(%{name: "test user b", email: "test_b@email.com"})
    {:ok, b} = User.add_initial_deposit(b)
    {:ok, c} = User.create(%{name: "test user c", email: "test_c@email.com"})
    {:ok, c} = User.add_initial_deposit(c)

    {:ok, brand} = Brand.create(%{name: "test brand #{:rand.uniform}"})
    {:ok, coupon_a} = Coupon.create(%{
      value: 500,
      unique_coupon_code: Ecto.UUID.generate(),
    }, a, brand)
    {:ok, coupon_b} = Coupon.create(%{
      value: 200,
      unique_coupon_code: Ecto.UUID.generate(),
    }, b, brand)
    {:ok, coupon_c} = Coupon.create(%{
      value: 700,
      unique_coupon_code: Ecto.UUID.generate(),
    }, c, brand)

    {:ok, _transaction_a} = Transaction.maybe_post(coupon_a, a)
    {:ok, coupon_a} = Coupon.find(coupon_a.id)
    {:ok, _transaction_a} = Transaction.maybe_request(coupon_a, b)

    {:ok, _transaction_b} = Transaction.maybe_post(coupon_b, b)
    {:ok, coupon_b} = Coupon.find(coupon_b.id)
    {:ok, _transaction_a} = Transaction.maybe_request(coupon_b, c)

    {:ok, _transaction_c} = Transaction.maybe_post(coupon_c, c)
    {:ok, coupon_c} = Coupon.find(coupon_c.id)
    {:ok, _transaction_a} = Transaction.maybe_request(coupon_c, a)

    expected_revenue = Enum.reduce([coupon_a, coupon_b, coupon_c], 0, fn(c, acc) ->
      acc + round(c.value * 0.05)
    end)

    assert CouponMarketplace.revenue == expected_revenue
  end
end