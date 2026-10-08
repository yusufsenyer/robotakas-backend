module ForumUserSerializer
  def self.render(user)
    { id: user.id, full_name: user.full_name, team_name: user.team_name }
  end
end
