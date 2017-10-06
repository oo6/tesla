defmodule Tesla.Middleware.TimeoutTest do
  use ExUnit.Case, async: false

  defmodule Client do
    use Tesla

    plug Tesla.Middleware.Timeout, timeout: 100

    adapter fn(env) ->
      status = case env.url do
        "/sleep_50ms" ->
          Process.sleep(50)
          200
        "/sleep_150ms" ->
          Process.sleep(150)
          200
      end

      %{env | status: status}
    end
  end

  defmodule DefaultTimeoutClient do
    use Tesla

    plug Tesla.Middleware.Timeout

    adapter fn(env) ->
      status = case env.url do
        "/sleep_950ms" ->
          Process.sleep(950)
          200
        "/sleep_1050ms" ->
          Process.sleep(1_050)
          200
      end

      %{env | status: status}
    end
  end

  describe "using custom timeout (100ms)" do 
    test "should raise a Tesla.Error when the stack timeout" do
      error = assert_raise Tesla.Error, fn ->
        Client.get("/sleep_150ms")
      end
      assert error.reason == :timeout
    end

    test "should return the response when not timeout" do
      assert %Tesla.Env{status: 200} = Client.get("/sleep_50ms")
    end
  end

  describe "using default timeout (1_000ms)" do 
    test "should raise a Tesla.Error when the stack timeout" do
      error = assert_raise Tesla.Error, fn ->
        DefaultTimeoutClient.get("/sleep_1050ms")
      end
      assert error.reason == :timeout
    end

    test "should return the response when not timeout" do
      assert %Tesla.Env{status: 200} = DefaultTimeoutClient.get("/sleep_950ms")
    end
  end
end
