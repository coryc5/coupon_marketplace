defmodule CouponMarketplace.CouponTest do
  use CouponMarketplace.DataCase, async: true

  setup do
    {:ok, brand} = Brand.create(%{name: "test brand"})

    coupon_params = %{
      value: 500,
      unique_coupon_code: Ecto.UUID.generate(),
      brand: brand
    }

    {:ok, coupon_params: coupon_params}
  end

  test "changeset with required params is valid", %{coupon_params: coupon_params} do
    changeset = Coupon.changeset(%Coupon{}, coupon_params)

    assert changeset.valid?
  end

  test "changeset without required params is invalid" do
    changeset = Coupon.changeset(%Coupon{}, %{brand: %Brand{}})

    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset, :value)
    assert "can't be blank" in errors_on(changeset, :unique_coupon_code)
  end

  test "create adds coupon to database", %{coupon_params: coupon_params} do
    {:ok, %Coupon{id: coupon_id}} =
      %Coupon{}
      |> Coupon.changeset(coupon_params)
      |> Repo.insert()

    {:ok, result_coupon} = Coupon.find(coupon_id)

    assert result_coupon.value == coupon_params.value
    assert result_coupon.unique_coupon_code == coupon_params.unique_coupon_code
    assert result_coupon.brand_id == coupon_params.brand.id
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
