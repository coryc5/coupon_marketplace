defmodule CouponMarketplace.UserTest do
  use CouponMarketplace.DataCase, async: true

  setup do
    user_params = %{
      name: "test user",
      email: "test@email.com"
    }

    {:ok, user_params: user_params}
  end

  test "create adds user to database", %{user_params: user_params} do
    {:ok, %User{id: user_id}} = User.create(user_params)

    {:ok, %User{
      name: result_name,
      email: result_email
    }} = User.find(user_id)

    assert result_name == user_params.name
    assert result_email == user_params.email
  end

  test "create overwrites initial_deposit as false", %{user_params: user_params} do
    {:ok, %User{id: user_id}} =
      user_params
      |> Map.merge(%{initial_deposit: true})
      |> User.create()

    {:ok, user} = User.find(user_id)

    assert user.initial_deposit == false
  end

  test "create without require params returns invalid changeset" do
    {:error, user_changeset} = User.create(%{})

    refute user_changeset.valid?
    assert "can't be blank" in errors_on(user_changeset, :name)
    assert "can't be blank" in errors_on(user_changeset, :email)
  end

  test "create rejects user with duplicate email" do
    input_name_a = "test user a"
    input_name_b = "test user b"
    duplicate_email = "duplicate@email.com"

    {:ok, _valid_user} = User.create(%{
      name: input_name_a,
      email: duplicate_email
    })

    {:error, user_changeset} = User.create(%{
      name: input_name_b,
      email: duplicate_email
    })

    refute user_changeset.valid?
    assert "has already been taken" in errors_on(user_changeset, :email)
  end

  test "find returns error for nonexistent users" do
    assert {:error, :not_found} == User.find(0)
    assert {:error, :bad_request} == User.find("bad id")
  end

  test "changeset ignores extra params", %{user_params: user_params} do
    user_changeset = User.changeset(%User{}, Map.merge(user_params, %{extra_param: "extra param"}))

    assert Map.get(user_changeset.changes, :extra_param) == nil
  end

  test "adding initial deposit updates user", %{user_params: user_params} do
    {:ok, %User{initial_deposit: false} = user} = User.create(user_params)
    {:ok, _updated_user} = User.add_initial_deposit(user)
    {:ok, result_user} = User.find(user.id)

    assert result_user.initial_deposit == true
    assert result_user.balance == 2000
  end

  test "cannot add initial deposit more than once", %{user_params: user_params} do
    {:ok, %User{initial_deposit: false} = user} = User.create(user_params)
    {:ok, updated_user} = User.add_initial_deposit(user)

    # updating a stale user should through an error
    assert_raise(Ecto.StaleEntryError, fn -> User.add_initial_deposit(user) end)

    {:error, user_changeset} = User.add_initial_deposit(updated_user)
    {:ok, result_user} = User.find(user.id)

    assert "already exists" in errors_on(user_changeset, :initial_deposit)
    assert result_user.initial_deposit == true
    assert result_user.balance == 2000
  end

  test "user can deposit", %{user_params: user_params} do
    {:ok, %User{initial_deposit: false} = user} = User.create(user_params)
    {:ok, updated_user} = User.add_initial_deposit(user)
    User.deposit(updated_user, 5000)
    {:ok, result_user} = User.find(user.id)

    assert result_user.balance == 7000
  end

  test "user cannot deposit until initial deposit made", %{user_params: user_params} do
    {:ok, %User{initial_deposit: false} = user} = User.create(user_params)
    assert User.deposit(user, 5000) == {:error, :user_has_not_made_initial_deposit}

    {:ok, result_user} = User.find(user.id)
    assert result_user.balance == 0
  end

  test "user can only deposit positive integers", %{user_params: user_params} do
    {:ok, %User{initial_deposit: false} = user} = User.create(user_params)
    {:ok, updated_user} = User.add_initial_deposit(user)

    assert {:error, :invalid_deposit} == User.deposit(updated_user, -5000)
    assert {:error, :invalid_deposit} == User.deposit(updated_user, 0)
    assert {:error, :invalid_deposit} == User.deposit(updated_user, 100.0)

    {:ok, result_user} = User.find(user.id)

    assert result_user.balance == 2000
  end
end
