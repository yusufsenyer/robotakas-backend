module PartSerializer
  def self.summary(part, listing_count: nil, min_price: nil)
    {
      id: part.id,
      code: part.code,
      slug: part.slug,
      name: part.name,
      brand: part.brand,
      category_id: part.category_id,
      category_path: part.category&.path,
      listing_count: listing_count || part.listings.active.count,
      min_price: min_price,
    }
  end

  def self.detail(part)
    listings = part.listings.active
    prices = listings.map(&:price)

    {
      id: part.id,
      code: part.code,
      slug: part.slug,
      name: part.name,
      brand: part.brand,
      category_id: part.category_id,
      description: part.description,
      specs: part.specs || [],
      category_path: part.category.path,
      price_summary: {
        count: prices.size,
        min: prices.min,
        avg: prices.empty? ? nil : (prices.sum.to_f / prices.size).round,
        max: prices.max,
      },
      listing_count: prices.size,
    }
  end
end
