module CategorySerializer
  def self.render_node(category, counts)
    child_nodes = category.children.map do |child|
      render_node(child, counts)
    end

    listing_count =
      if child_nodes.empty?
        counts.fetch(category.id, 0)
      else
        child_nodes.sum { |child| child[:listing_count] }
      end

    {
      id: category.id,
      name: category.name,
      slug: category.slug,
      icon_key: category.icon_key,
      position: category.position,
      listing_count: listing_count,
      children: child_nodes,
    }
  end
end
