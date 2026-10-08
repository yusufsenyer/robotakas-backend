module ForumText
  CONTROL_CHARS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/

  def self.clean(value)
    value.to_s.gsub(CONTROL_CHARS, "").strip
  end
end
