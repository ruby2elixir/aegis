defmodule Aegis do
  @moduledoc """
  Lightweight, flexible authorization.
  """

  @doc """
  Returns `true` if a user is authorized to perform an action on a given resource as dictated by the resource's corresponding policy definition.


  ## Example

  ```
  defmodule Puppy do
    defstruct [id: nil, user_id: nil, hungry: false]
  end

  defmodule Puppy.Policy do
    @behaviour Aegis.Policy

    def authorize(_user, :index, _puppy), do: true
  end

  defmodule Kitten do
    defstruct [id: nil, user_id: nil, hungry: false]
  end
  ```

    iex> user = :user
    iex> resource = Puppy
    iex> Aegis.authorized?(user, :index, resource)
    true
    iex> Aegis.authorized?(user, :show, resource)
    false

    iex> user = :user
    iex> action = :index
    iex> resource = Kitten
    iex> Aegis.authorized?(user, action, resource)
    ** (RuntimeError) Policy not found: Elixir.Kitten.Policy
  """
  @spec authorized?(user :: any, action :: atom, resource :: any) :: boolean
  def authorized?(user, action, resource) do
    resource
    |> fetch_policy_module
    |> authorized?(user, action, resource)
  end

  @spec authorized?(mod :: module, user :: any, action :: atom, resource :: any) :: boolean
  def authorized?(mod, user, action, resource) do
    apply(mod, :authorize, [user, action, resource])
  end

  @doc """
  Returns scope for a resource for a user for a given action as dictated by the
  resource's corresponding policy definition.


  ## Example

  ```
  defmodule Puppy do
    defstruct [id: nil, user_id: nil, hungry: false]
  end

  defmodule Puppy.Policy do
    @behaviour Aegis.Policy

    def scope(_user, _scope, :index), do: :index_scope
    def scope(_user, _scope, :show), do: :show_scope
  end

  defmodule Kitten do
    defstruct [id: nil, user_id: nil, hungry: false]
  end
  ```

      iex> user = :user
      iex> scope = %{from: {"puppies", Puppy}}
      iex> Aegis.auth_scope(user, scope, :index)
      :index_scope
      iex> Aegis.auth_scope(user, scope, :show)
      :show_scope

      iex> user = :user
      iex> scope = %{from: {"kittens", Kitten}}
      iex> Aegis.auth_scope(user, scope, :index)
      ** (RuntimeError) Policy not found: Elixir.Kitten.Policy
  """
  @spec auth_scope(user :: any, scope :: any, action :: atom) :: any
  def auth_scope(user, scope, action) do
    scope
    |> fetch_policy_module
    |> auth_scope(user, scope, action)
  end

  @spec auth_scope(mod :: module, user :: any, scope :: any, action :: atom) :: any
  def auth_scope(mod, user, scope, action) do
    apply(mod, :scope, [user, scope, action])
  end

  @spec fetch_policy_module(any) :: module | :error
  def fetch_policy_module(arg) do
    case Aegis.PolicyFinder.call(arg) do
      {:error, nil} -> raise "No Policy for nil object"
      {:error, mod} -> raise "Policy not found: #{mod}"
      {:ok, mod} -> mod
    end
  end
end
