defmodule CouponMarketplace.BalanceTransactionTest do
  use CouponMarketplace.DataCase, async: true

  test "changeset with missing params is invalid" do
    changeset = BalanceTransaction.changeset(%BalanceTransaction{}, %{})

    refute changeset.valid?

    assert "can't be blank" in errors_on(changeset, :amount)
    assert "can't be blank" in errors_on(changeset, :user_id)
  end

  test "changeset removes extra params" do
    changeset = BalanceTransaction.changeset(%BalanceTransaction{}, %{
      amount: 500,
      user_id: 1,
      extra_params: "extra_params"
    })

    assert Map.get(changeset.changes, :extra_params) == nil
  end
end
