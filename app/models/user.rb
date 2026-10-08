class User < ApplicationRecord
  has_secure_password

  has_many :listings, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_listings, through: :favorites, source: :listing
  has_many :saved_searches, dependent: :destroy
  has_many :conversations, foreign_key: :buyer_id, dependent: :destroy
  has_many :reports, foreign_key: :reporter_id, dependent: :destroy
  has_many :announcement_reads, dependent: :destroy
  has_many :forum_topics, dependent: :destroy
  has_many :forum_posts, dependent: :destroy
  has_many :forum_likes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :destroy

  before_validation :normalize_email
  before_validation :normalize_phone

  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :city, presence: true
  validates :role, inclusion: { in: %w[user admin] }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :phone, format: {
    with: /\A05\d{9}\z/,
    message: "geçerli bir Türkiye cep numarası olmalı"
  }, allow_nil: true

  def admin?
    role == "admin"
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def normalize_phone
    self.phone = phone.to_s.gsub(/[\s\-()]/, "").presence
  end
end
