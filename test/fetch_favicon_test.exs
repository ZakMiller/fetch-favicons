defmodule FetchFaviconTest do
  use ExUnit.Case

  import Mock

  test "invalid html returned" do
    with_mock HTTPoison, get: fn _, _, _ -> {:ok, ""} end do
      assert {:error, _} = FetchFavicon.fetch("reddit.com")
    end
  end

  test "error returned" do
    with_mock HTTPoison, get: fn _, _, _ -> {:error, "error message"} end do
      assert {:error, _} = FetchFavicon.fetch("reddit.com")
    end
  end

  test "first call fails" do
    base_site_response = %HTTPoison.Response{
      body: "<html><link href=\"/custom/reddit/ico/path/icon.ico\" rel=\"shortcut icon\"></html>",
      headers: [{"Content-Type", "text/html; charset=UTF-8"}, {"Content-Length", "non zero"}],
      request_url: "",
      status_code: 200
    }

    image_response = %HTTPoison.Response{
      body: "some valid image",
      headers: [{"Content-Type", "image/x-icon"}, {"Content-Length", "non zero"}],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://reddit.com/favicon.ico" ->
            {:error, "error messsage"}

          "http://reddit.com" ->
            {:ok, base_site_response}

          "http://reddit.com/custom/reddit/ico/path/icon.ico" ->
            {:ok, image_response}

          _ ->
            nil
        end
      end do
      assert {:ok, _} = FetchFavicon.fetch("reddit.com")
    end
  end

  test "trailing slash" do
    response = %HTTPoison.Response{
      body: "<html></html>",
      headers: [{"Content-Type", "image/x-icon"}, {"Content-Length", "non zero"}],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://reddit.com/favicon.ico" ->
            {:ok, response}

          _ ->
            nil
        end
      end do
      assert {:ok, _} = FetchFavicon.fetch("reddit.com/")
    end
  end

  test "not image" do
    response = %HTTPoison.Response{
      body: "<html></html>",
      headers: [{"Content-Type", "text/html; charset=utf-8"}, {"Content-Length", "non zero"}],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://reddit.com/favicon.ico" ->
            {:ok, response}

          _ ->
            {:error, "error message"}
        end
      end do
      assert {:error, _} = FetchFavicon.fetch("reddit.com/")
    end
  end

  test "has encoding" do
    response = %HTTPoison.Response{
      body: "<html></html>",
      headers: [
        {"Content-Type", "text/html; charset=utf-8"},
        {"Content-Length", "non zero"},
        {"Content-Encoding", "gzip"}
      ],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://reddit.com/favicon.ico" ->
            {:ok, response}

          _ ->
            {:error, "error message"}
        end
      end do
      assert {:error, _} = FetchFavicon.fetch("reddit.com/")
    end
  end

  test "content length 0" do
    response = %HTTPoison.Response{
      body: "",
      headers: [
        {"Content-Type", "image/png"},
        {"Content-Length", "0"}
      ],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://reddit.com/favicon.ico" ->
            {:ok, response}

          _ ->
            {:error, "error message"}
        end
      end do
      assert {:error, _} = FetchFavicon.fetch("reddit.com/")
    end
  end

  test "invalid image" do
    response = %HTTPoison.Response{
      body: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAGXR
      FWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA99JREFUeNrsG4t1ozDMzQSM4A2ODUo9nKB
      ucN2hugtIJ6E1AboLcBiQTkJsANiAb9OCd/OpzMWBJBl5TvaeXPiiyJetry0J8wW3wefawefN4II=\n",
      headers: [
        {"Content-Type", "image/png"}
      ],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://reddit.com/favicon.ico" ->
            {:error, "error message"}

          "http://reddit.com/" ->
            {:ok, response}

          _ ->
            {:error, "error message"}
        end
      end do
      assert {:error, _} = FetchFavicon.fetch("reddit.com/")
    end
  end

  test "www" do
    response = %HTTPoison.Response{
      body: "<html></html>",
      headers: [{"Content-Type", "image/png"}, {"Content-Length", "non zero"}],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://www.reddit.com/favicon.ico" ->
            {:ok, response}

          _ ->
            nil
        end
      end do
      assert {:ok, _} = FetchFavicon.fetch("www.reddit.com/")
    end
  end

  test "first and second calls fail" do
    response = %HTTPoison.Response{
      body: "image",
      headers: [{"Content-Type", "image/x-icon"}, {"Content-Length", "non zero"}],
      request_url: "",
      status_code: 200
    }

    with_mock HTTPoison,
      get: fn url, _, _ ->
        case url do
          "http://reddit.com/favicon.ico" ->
            {:error, "error messsage"}

          "http://reddit.com" ->
            {:error, "error messsage"}

          "https://www.google.com/s2/favicons?domain=reddit.com" ->
            {:ok, response}

          _ ->
            {:error, "error messsage"}
        end
      end do
      assert {:ok, _} = FetchFavicon.fetch("reddit.com")
    end
  end
end
