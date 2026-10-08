class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, -> { order(:position, :id) },
    class_name: "Category", foreign_key: "parent_id", dependent: :destroy
  has_many :parts, dependent: :destroy
  has_many :listings, dependent: :destroy
  has_many :listing_compatible_categories, dependent: :destroy

  before_validation :set_slug, if: -> { slug.blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :roots, -> { where(parent_id: nil).order(:position, :id) }
  scope :leaves, -> { where.not(id: Category.where.not(parent_id: nil).select(:parent_id)) }

  def self.slug_for(name, parent = nil)
    base = normalize_slug(name)
    return base if parent.nil?

    "#{parent.slug}-#{base}"
  end

  def root?
    parent_id.nil?
  end

  def leaf?
    children.none?
  end

  def descendant_ids
    [id] + children.flat_map(&:descendant_ids)
  end

  def path
    parts = []
    node = self
    while node
      parts.unshift(node.name)
      node = node.parent
    end
    parts.join(" / ")
  end

  def self.normalize_slug(value)
    value.to_s
      .gsub("İ", "i").gsub("I", "i")
      .gsub("Ç", "c").gsub("Ğ", "g").gsub("Ö", "o").gsub("Ş", "s").gsub("Ü", "u")
      .downcase
      .gsub("ç", "c").gsub("ğ", "g").gsub("ı", "i").gsub("ö", "o").gsub("ş", "s").gsub("ü", "u")
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/\A-+|-+\z/, "")
  end

  private

  def set_slug
    self.slug = self.class.slug_for(name, parent)
  end
end
