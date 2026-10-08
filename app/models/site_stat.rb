class SiteStat < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.add!(key, amount = 1)
    stat = find_or_create_by!(key: key.to_s)
    stat.increment!(:value, amount)
  end

  def self.value(key)
    find_by(key: key.to_s)&.value.to_i
  end
end
