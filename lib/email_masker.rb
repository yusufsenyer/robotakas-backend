module EmailMasker
  MASK = "•••".freeze

  def self.call(email)
    local, domain = email.to_s.split("@", 2)
    return MASK if local.blank? || domain.blank?

    "#{local[0]}#{MASK}@#{domain}"
  end
end
