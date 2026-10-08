module ForumSeeder
  COMPETITION = [
    { slug: "mini-sumo", name: "Mini Sumo", description: "Mini Sumo robotları: tasarım, parça seçimi, strateji ve yarışma soruları." },
    { slug: "cizgi-izleyen-temel-seviye", name: "Çizgi İzleyen (Temel Seviye)", description: "Temel seviye çizgi izleyen robotlar ve yarışma soruları." },
    { slug: "hizli-cizgi-izleyen", name: "Hızlı Çizgi İzleyen", description: "Hızlı çizgi izleyen robotlar: hız, kontrol ve yarışma soruları." },
    { slug: "labirent-ustasi", name: "Labirent Ustası", description: "Labirent çözen robotlar: sensörler, algoritma ve strateji." },
    { slug: "tozkoparan-robot", name: "Tozkoparan Robot", description: "Tozkoparan robot kategorisi: tasarım, atış düzeni ve yarışma soruları." },
    { slug: "yumurta-toplama", name: "Yumurta Toplama", description: "Yumurta toplama robotları: mekanizma, kontrol ve yarışma soruları." },
    { slug: "tasarla-calistir", name: "Tasarla-Çalıştır", description: "Tasarla-Çalıştır kategorisi: tasarım, üretim ve yarışma soruları." },
    { slug: "endustriyel-robotik-kol", name: "Endüstriyel Robotik Kol", description: "Robotik kol projeleri: mekanik, kontrol ve yarışma soruları." },
    { slug: "insansiz-hava-araci-mini-drone", name: "İnsansız Hava Aracı (Mini Drone)", description: "Mini drone projeleri: uçuş, kontrol ve yarışma soruları." },
    { slug: "rc-sabit-kanat-ucak", name: "RC Sabit Kanat Uçak", description: "RC sabit kanat uçaklar: tasarım, uçuş ve yarışma soruları." },
    { slug: "su-alti-robot", name: "Su Altı Robot", description: "Su altı robotları: su geçirmezlik, itki ve yarışma soruları." },
    { slug: "su-ustu-robot", name: "Su Üstü Robot", description: "Su üstü robotları: denge, itki ve yarışma soruları." },
    { slug: "otonom-arac", name: "Otonom Araç", description: "Otonom araçlar: algılama, karar verme ve yarışma soruları." },
    { slug: "serbest-proje", name: "Serbest Proje", description: "Serbest projeler: fikir, tasarım ve yarışma soruları." },
    { slug: "siber-guvenlik", name: "Siber Güvenlik", description: "Siber güvenlik kategorisi: yarışma soruları ve hazırlık." }
  ].freeze

  GENERAL = [
    { slug: "yeni-baslayanlar", name: "Yeni başlayanlar", description: "Robota yeni mi başlıyorsun? Soru sormaktan çekinme." },
    { slug: "genel-sohbet", name: "Genel sohbet", description: "Yarışma, takım ve robotlar hakkında serbest sohbet." },
    { slug: "duyurular-ve-oneriler", name: "Duyurular ve öneriler", description: "Site ve yarışma duyuruları, RoboTakas için önerilerin." }
  ].freeze

  def self.seed_boards!
    created = 0

    COMPETITION.each_with_index do |board, index|
      created += 1 if create_competition_board(board, index)
    end
    GENERAL.each_with_index do |board, index|
      created += 1 if create_general_board(board, index)
    end

    created
  end

  def self.create_competition_board(attrs, position)
    return false if ForumBoard.exists?(slug: attrs[:slug])

    category = Category.find_by(slug: attrs[:slug])
    ForumBoard.create!(
      name: category&.name || attrs[:name],
      slug: attrs[:slug],
      description: attrs[:description],
      icon_key: category&.icon_key,
      kind: "competition",
      position: position,
    )
    true
  end

  def self.create_general_board(attrs, position)
    return false if ForumBoard.exists?(slug: attrs[:slug])

    ForumBoard.create!(
      name: attrs[:name],
      slug: attrs[:slug],
      description: attrs[:description],
      kind: "general",
      position: position,
    )
    true
  end
end
