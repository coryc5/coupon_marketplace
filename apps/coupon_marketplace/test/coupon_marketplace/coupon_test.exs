defmodule CouponMarketplace.CouponTest do
  use CouponMarketplace.DataCase, async: true

  setup do
    {:ok, brand} = Brand.create(%{name: "test brand"})
    {:ok, user} = User.create(%{
      name: "test user",
      email: "test@email.com"
    })
    {:ok, user} = User.add_initial_deposit(user)

    coupon_params = %{
      value: 500,
      unique_coupon_code: Ecto.UUID.generate()
    }

    {:ok, coupon_params: coupon_params, brand: brand, user: user}
  end

  test "changeset with required params is valid", %{coupon_params: coupon_params} do
    changeset = Coupon.changeset(%Coupon{}, coupon_params)

    assert changeset.valid?
  end

  test "cannot create coupon without initial deposit" do
     result = Coupon.create(%{}, %User{initial_deposit: false}, %Brand{})
     assert result == {:error, :user_has_not_made_initial_deposit}
  end

  test "create without required params results in invalid changeset" do
    {:error, changeset} = Coupon.create(%{}, %User{initial_deposit: true}, %Brand{})

    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset, :value)
    assert "can't be blank" in errors_on(changeset, :unique_coupon_code)
  end

  test "create adds coupon to database", %{coupon_params: coupon_params, brand: brand, user: user} do
    {:ok, %Coupon{id: coupon_id}} = Coupon.create(coupon_params, user, brand)

    {:ok, result_coupon} = Coupon.find(coupon_id)

    assert result_coupon.value == coupon_params.value
    assert result_coupon.unique_coupon_code == coupon_params.unique_coupon_code
    assert result_coupon.brand_id == brand.id
    assert result_coupon.owner_id == user.id
  end

  test "create returns error when trying to duplicate unique_coupon_code", %{coupon_params: coupon_params} do
    {:ok, _coupon} =
      %Coupon{}
      |> Coupon.changeset(coupon_params)
      |> Repo.insert()

    {:error, changeset} =
      %Coupon{}
      |> Coupon.changeset(coupon_params)
      |> Repo.insert()

    refute changeset.valid?
    assert "has already been taken" in errors_on(changeset, :unique_coupon_code)
  end

  test "create returns error when value < 0", %{coupon_params: coupon_params} do
    invalid_coupon_params = %{coupon_params | value: 0}
    {:error, changeset} =
      %Coupon{}
      |> Coupon.changeset(invalid_coupon_params)
      |> Repo.insert()

    refute changeset.valid?
    assert "is not greater than 0" in errors_on(changeset, :value)
  end

  test "find returns error for nonexistent coupons" do
    assert {:error, :not_found} == Coupon.find(0)
    assert {:error, :bad_request} == Coupon.find("bad id")
  end
end
