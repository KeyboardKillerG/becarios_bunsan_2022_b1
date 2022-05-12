defmodule GitHub do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.github.com"
  plug Tesla.Middleware.Headers, 
    [
      {"Authorization", "token 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"},
      {"User-Agent", "Tesla"}
    ]
  
  plug Tesla.Middleware.JSON

  def user_repos(login) do
    get!("/users/" <> login <> "/repos")
    |> Map.get(:body)
    |> Enum.drop(1)
    |> Enum.map(&(&1["name"]))
  end

  def repo_info(login, repo) do
    %{
      repo_name: get!("/repos/#{login}/#{repo}").body["name"],
      total_commits: length(get!("repos/#{login}/#{repo}/commits").body), 
      langs: get!("repos/#{login}/#{repo}/languages").body
    }
  end
end
