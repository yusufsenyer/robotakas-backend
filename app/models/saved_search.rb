class SavedSearch < ApplicationRecord
  ALLOWED_KEYS = %w[q kategori part durum min max sehir yarisma sirala].freeze
  MAX_PER_USER = 20

  belongs_to :user

  before_validation :sanitize_params

  validate :params_presence
  validate :max_per_user, on: :create

  def self.generate_name(params)
    parts = []

    parts << params["q"] if params["q"].present?

    if params["kategori"].present?
      category = Category.find_by(slug: params["kategori"])
      parts << category.name if category
    end

    if params["part"].present?
      part = Part.find_by(slug: params["part"])
      parts << part.code if part
    end

    case params["durum"]
    when "new" then parts << "Sıfır"
    when "used" then parts << "İkinci el"
    end

    if params["min"].present? || params["max"].present?
      min = params["min"].presence || "0"
      max = params["max"].presence || "∞"
      parts << "#{min}–#{max} ₺"
    end

    parts << params["sehir"] if params["sehir"].present?

    parts.any? ? parts.join(" · ") : "Tüm ilanlar"
  end

  private

  def sanitize_params
    self.params = (params || {}).to_h.stringify_keys.slice(*ALLOWED_KEYS).compact_blank
  end

  def params_presence
    errors.add(:params, "en az bir filtre gerekli") if params.blank?
  end

  def max_per_user
    if user && user.saved_searches.count >= MAX_PER_USER
      errors.add(:base, "en fazla #{MAX_PER_USER} kayıtlı arama olabilir")
    end
  end
end
