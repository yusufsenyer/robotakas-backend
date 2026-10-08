module PersonalInfoMasker
  MASK = "•••".freeze

  EMAIL = /[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/
  PHONE = /(?<![\w])(?:(?:\+?90)|0)?[\s.\-]?5\d{2}[\s.\-]?\d{3}[\s.\-]?\d{2}[\s.\-]?\d{2}(?![\w])/

  def self.call(text)
    value = text.to_s
    masked = value.gsub(EMAIL, MASK).gsub(PHONE, MASK)
    [ masked, masked != value ]
  end
end
