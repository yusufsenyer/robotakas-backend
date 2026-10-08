module UserSerializer
  def self.render(user, include_phone: false)
    data = {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      city: user.city,
      team_name: user.team_name,
      role: user.role,
      created_at: user.created_at.iso8601,
    }
    data[:phone] = user.phone if include_phone
    data
  end
end
