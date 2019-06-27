defmodule ExampleWeb.FileController do
  use ExampleWeb, :controller

  alias Example.HttpStream

  action_fallback StorageWeb.FallbackController

  def show(conn, _params) do
    url = "http://localhost:8080/Bigfile.mp4"
    %{headers: proxy_headers} = HTTPoison.head!(url)
    proxy_headers = for {k, v} <- proxy_headers, do: {String.downcase(k), v}, into: %{}

    chunked_conn =
      conn
      |> put_resp_content_type("video/mp4")
      |> put_resp_header("content-length", proxy_headers["content-length"])
      |> send_chunked(200)

    url
    |> HttpStream.stream()
    |> Stream.map(fn n -> chunk(chunked_conn, n) end)
    |> Stream.run()
  end
end
