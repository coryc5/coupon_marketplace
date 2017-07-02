defmodule CouponMarketplace.BrandTest do
  use CouponMarketplace.DataCase

  test "create adds brand to database" do
    input_name = "test brand"
    {:ok, %Brand{id: brand_id}} = Brand.create(%{name: input_name})
    %Brand{name: result_name} = Repo.get(Brand, brand_id)

    assert result_name == input_name
  end

  test "create without name returns invalid changeset" do
    {:error, brand_changeset} = Brand.create(%{})

    refute brand_changeset.valid?
    assert "can't be blank" in errors_on(brand_changeset, :name)
  end

  test "create ignores extra params" do
    input_name = "test brand"
    {:ok, %Brand{id: brand_id}} = Brand.create(%{
      name: input_name,
      extra_param: "extra param"
    })

    brand = Repo.get(Brand, brand_id)

    assert Map.get(brand, :extra_param) == nil
  end
end