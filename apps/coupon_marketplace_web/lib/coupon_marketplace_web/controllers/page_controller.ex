defmodule CouponMarketplace.Web.PageController do
  use CouponMarketplace.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
