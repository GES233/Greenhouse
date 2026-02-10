# Required test
defmodule Greenhouse.Taxonomy.CategoryItem do
  @type t :: %__MODULE__{
          name: atom(),
          relative_depth: non_neg_integer(),
          child: t(),
          posts: [atom() | binary()]
        }
  defstruct [:name, :relative_depth, :child, :posts]
  # 因为属别与帖子是多对多的关系，所以这里的帖子只保留 id

  @init_node_name "未归类"

  def init_node(),
    do: %__MODULE__{
      name: @init_node_name,
      relative_depth: 0,
      child: [],
      posts: []
    }
end

defmodule Greenhouse.Taxonomy.Categories do
  alias Greenhouse.Taxonomy.CategoryItem, as: Node

  def get_id_categories_pair(posts_map) do
    posts_map
    |> Enum.map(fn {id, post} -> {id, post.index_view[:categories]} end)
    |> Enum.reject(fn {_, maybe_series} -> is_nil(maybe_series) end)
  end

  def get_all_categories_from_posts(id_categories_pair) do
    id_categories_pair
    |> Enum.reduce([], fn {_id, categories}, acc -> [categories | acc] end)
    |> Enum.uniq()
  end

  def get_all_posts_from_specific_category(id_categories_pair, category_name) do
    # 最好用未归类的
    categories = get_all_categories_from_posts(id_categories_pair)

    cond do
      category_name not in categories ->
        []

      true ->
        id_categories_pair
        |> Enum.filter(fn {_id, categories} -> category_name in categories end)
        |> Enum.map(fn {id, _} -> id end)
    end
  end

  # 将 categories 整合为树形结构
  @doc """
  从所有文章中提取分类并构建树形结构。

  参数: posts - [%{categories: [list(binary)]}]
  返回: %Node{} 的树形结构
  """
  def build_category_tree(id_categories_pair) do
    id_categories_pair
    |> Enum.flat_map(fn {id, c} -> Enum.map(c, &{&1, id}) end)
    |> Enum.reduce(Node.init_node(), fn {category_path, post_id}, acc ->
      insert_category(acc, List.wrap(category_path), post_id, 0)
    end)
  end

  # 递归插入分类路径到树中
  defp insert_category(%Node{} = node, [current | rest], post_id, depth) do
    # 将字符串转为 atom
    # current_atom = String.to_atom(current)

    # 查找或创建当前层级的子节点
    {matched_child, other_children} =
      Enum.split_with(node.child, fn %Node{name: name} -> name == current end)

    child_node =
      case matched_child do
        [] ->
          # 创建新节点
          %Node{
            name: current,
            relative_depth: depth,
            child: [],
            posts: [post_id]
          }

        [existing | _] when is_struct(existing, Node) ->
          # 更新已有节点的 posts
          %{existing | posts: [post_id | existing.posts]}
      end

    # 如果还有剩余路径，继续递归
    updated_child =
      if rest != [] do
        insert_category(child_node, rest, post_id, depth + 1)
      else
        child_node
      end

    # 更新当前节点的子节点列表
    %Node{node | child: [updated_child | other_children]}
  end

  defp insert_category(%Node{} = node, [], post_id, _depth) do
    # 没有分类路径时，将文章放入当前节点
    %Node{node | posts: [post_id | node.posts]}
  end

  # def add_posts
end
