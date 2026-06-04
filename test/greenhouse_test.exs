defmodule GreenhouseTest do
  use ExUnit.Case
  doctest Greenhouse

  test "greets the world" do
    assert Greenhouse.hello() == :world
  end

  describe "Greenhouse.Cite.ContentReplacer" do
    alias Greenhouse.Cite.ContentReplacer
    alias Greenhouse.Content.Post

    defp make_post(id, content) do
      {id,
       %Post{
         id: id,
         title: "Test",
         content: content,
         created_at: ~U[2024-01-01T00:00:00Z],
         updated_at: ~U[2024-01-01T00:00:00Z]
       }}
    end

    test "replaces [[post-id]] with post URL" do
      posts = %{
        "source" => make_post("source", "See [[target-post]] for details.") |> elem(1),
        "target-post" =>
          make_post("target-post", "Hello") |> elem(1)
      }

      {updated_posts, _updated_pages} =
        ContentReplacer.replace_posts(posts, %{}, %{})
        |> then(fn {ps, pg} -> {Enum.into(ps, %{}), Enum.into(pg, %{})} end)

      assert updated_posts["source"].content ==
               "See /2024/1/target-post for details."
    end

    test "replaces [[media]] with media route" do
      posts = %{
        "my-post" =>
          make_post("my-post", "Look at [[my-image]]") |> elem(1)
      }

      media = %{
        "my-image" => %Greenhouse.Asset.Media{
          type: Greenhouse.Asset.Media.Picture,
          route_path: "image/my-image.png",
          abs_loc: "/tmp/my-image.png"
        }
      }

      {updated_posts, _} = ContentReplacer.replace_posts(posts, %{}, media) |> then(fn {ps, pg} -> {Enum.into(ps, %{}), Enum.into(pg, %{})} end)
      assert updated_posts["my-post"].content == "Look at /image/my-image.png"
    end

    test "leaves text without wikilinks unchanged" do
      posts = %{
        "p" => make_post("p", "No links here.") |> elem(1)
      }

      {updated, _} = ContentReplacer.replace_posts(posts, %{}, %{}) |> then(fn {ps, pg} -> {Enum.into(ps, %{}), Enum.into(pg, %{})} end)
      assert updated["p"].content == "No links here."
    end

    test "handles multiple wikilinks in one post" do
      posts = %{
        "multi" =>
          make_post("multi", "See [[a]] and [[b]].") |> elem(1),
        "a" => make_post("a", "A") |> elem(1),
        "b" => make_post("b", "B") |> elem(1)
      }

      {updated, _} = ContentReplacer.replace_posts(posts, %{}, %{}) |> then(fn {ps, pg} -> {Enum.into(ps, %{}), Enum.into(pg, %{})} end)
      assert updated["multi"].content == "See /2024/1/a and /2024/1/b."
    end
  end
end
