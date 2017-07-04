defmodule CouponMarketplace do
  use CouponMarketplace.Aliases

  @spec users :: [User.t]
  def users, do: Repo.all(User)

  @spec transactions :: [Transaction.t]
  def transactions, do: Repo.all(Transaction)

  @spec revenue :: non_neg_integer
  def revenue, do: Repo.aggregate(Transaction, :sum, :marketplace_share) || 0
end
