defmodule CouponMarketplace.BrandTest do
  use CouponMarketplace.DataCase, async: true

  test "create adds brand to database" do
    input_name = "test brand #{:rand.uniform}"
    {:ok, %Brand{id: brand_id}} = Brand.create(%{name: input_name})
    %Brand{name: result_name} = Repo.get(Brand, brand_id)

    assert result_name == input_name
  end

  test "same brand name cannot be created twice" do
    input_name = "test brand #{:rand.uniform}"
    {:ok, _brand} = Brand.create(%{name: input_name})
    {:error, changeset} = Brand.create(%{name: input_name})

    refute changeset.valid?
    assert "has already been taken" in errors_on(changeset, :name)
  end

  test "create without name returns invalid changeset" do
    {:error, brand_changeset} = Brand.create(%{})

    refute brand_changeset.valid?
    assert "can't be blank" in errors_on(brand_changeset, :name)
  end

  test "create ignores extra params" do
    input_name = "test brand #{:rand.uniform}"
    {:ok, %Brand{id: brand_id}} = Brand.create(%{
      name: input_name,
      extra_param: "extra param"
    })

    brand = Repo.get(Brand, brand_id)

    assert Map.get(brand, :extra_param) == nil
  end
end
