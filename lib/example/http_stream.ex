defmodule Example.HttpStream do
  def stream(url, headers \\ []) do
    Stream.resource(
      fn -> build_stream(url, headers) end,
      fn resp -> read_stream(resp) end,
      fn _resp -> :ok end
    )
  end

  defp build_stream(remote_file_url, headers) do
    HTTPoison.get!(remote_file_url, headers, stream_to: self(), async: :once)
  end

  defp read_stream(resp) do
    %HTTPoison.AsyncResponse{id: ref} = resp

    receive do
      %HTTPoison.AsyncStatus{id: ^ref} ->
        continue(resp)

      %HTTPoison.AsyncHeaders{id: ^ref, headers: _headers} ->
        continue(resp)

      %HTTPoison.AsyncChunk{chunk: chunk, id: ^ref} ->
        _ = stream_next(resp)
        {[chunk], resp}

      %HTTPoison.AsyncEnd{id: ^ref} ->
        {:halt, resp}
    end
  end

  defp continue(resp) do
    resp
    |> stream_next
    |> read_stream
  end

  defp stream_next(resp) do
    {:ok, ^resp} = HTTPoison.stream_next(resp)
    resp
  end
end
