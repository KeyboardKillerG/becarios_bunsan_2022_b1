defmodule GitHub do
  def user_repos(client, login) do
    Tesla.get!(client, "/users/" <> login <> "/repos")
    |> Map.get(:body)
    |> Enum.drop(1)
    |> Enum.map(&(&1["name"]))
  end

  def repo_info(client, login, repo) do
    %{
      repo_name: Tesla.get!(client, "/repos/#{login}/#{repo}").body["name"],
      total_commits: length(Tesla.get!(client, "repos/#{login}/#{repo}/commits").body), 
      langs: Tesla.get!(client, "repos/#{login}/#{repo}/languages").body
    }
  end

  def client(token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.github.com"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [
        {"authorization", "token: " <> token },
        {"User-Agent", "Tesla"}
      ]}
    ]

    Tesla.client(middleware)
  end
end
