use CouponMarketplace.Aliases

brands = Enum.map(["Amazon", "iTunes", "Barney's"], fn(name) ->
  {:ok, brand} = Brand.create(%{name: name})
  brand
end)

users = Enum.map(1..100, fn(n) ->
  {:ok, user} = User.create(%{name: "#{n}", email: "#{n}@email.com"})
  {:ok, user} = User.add_initial_deposit(user)

  user
end)

coupons = Enum.map(users, fn(user) ->
  brand = Enum.random(brands)

  {:ok, coupon} = Coupon.create(%{
    value: round(:rand.uniform() * 1000),
    unique_coupon_code: Ecto.UUID.generate()
  }, user, brand)

  coupon
end)

coupons = coupons |> Enum.shuffle() |> Enum.take(50)

Enum.each(coupons, fn(coupon) -> Transaction.maybe_post(coupon, coupon.owner) end)

coupons
|> Stream.map(fn(%{id: coupon_id}) -> Coupon.find(coupon_id) end)
|> Stream.map(fn({:ok, coupon}) -> coupon end)
|> Enum.each(fn(coupon) -> Transaction.maybe_request(coupon, Enum.random(users)) end)
