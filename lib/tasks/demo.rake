namespace :demo do
  desc "Örnek konuşma ve duyuru verisi oluşturur (idempotent, veri silmez)"
  task sample_data: :environment do
    if Conversation.exists? || Announcement.exists?
      puts "Örnek veri zaten mevcut, hiçbir şey yapılmadı."
      next
    end

    demo1 = User.find_by(email: "demo1@robotakas.test")
    demo2 = User.find_by(email: "demo2@robotakas.test")
    demo3 = User.find_by(email: "demo3@robotakas.test")
    admin = User.find_by(role: "admin")

    unless demo1 && demo2 && demo3 && admin
      puts "Demo kullanıcıları ya da admin bulunamadı. Önce bin/rails db:seed çalıştır."
      next
    end

    def add_message(conversation, sender, body, read:)
      conversation.messages.create!(sender: sender, body: body, read_at: read ? Time.current : nil)
    end

    def finish_conversation(conversation)
      conversation.update!(last_message_at: conversation.messages.order(:id).last.created_at)
    end

    # Konuşma 1: demo2 alıcı, demo1 satıcı (demo1'in ilanı), demo1 için okunmamış.
    listing1 = demo1.listings.active.first
    if listing1
      c1 = Conversation.create!(listing: listing1, buyer: demo2)
      add_message(c1, demo2, "Merhaba, ilandaki #{listing1.part&.code || 'ürün'} hâlâ satışta mı?", read: true)
      add_message(c1, demo1, "Evet, duruyor. Hafta içi kargolayabilirim.", read: true)
      add_message(c1, demo2, "Süper, Ankara içi elden teslim olur mu?", read: false)
      finish_conversation(c1)
    end

    # Konuşma 2: demo3 alıcı, demo1 satıcı, demo3 için okunmamış.
    listing2 = demo1.listings.active.offset(1).first
    if listing2
      c2 = Conversation.create!(listing: listing2, buyer: demo3)
      add_message(c2, demo3, "#{listing2.part&.code || 'Bu ilan'} için fiyatta pazarlık payı var mı?", read: true)
      add_message(c2, demo1, "Az kullanıldı, fiyatı uygun. Yine de biraz indirim yapabilirim.", read: false)
      finish_conversation(c2)
    end

    # Konuşma 3: demo1 alıcı, demo2 satıcı, hepsi okunmuş.
    listing3 = demo2.listings.active.first
    if listing3
      c3 = Conversation.create!(listing: listing3, buyer: demo1)
      add_message(c3, demo1, "Merhaba, #{listing3.part&.code || 'bu ürün'} sıfır mı?", read: true)
      add_message(c3, demo2, "Evet, hiç açılmadı. Kutusunda duruyor.", read: true)
      finish_conversation(c3)
    end

    Announcement.create!(
      admin: admin,
      title: "RoboTakas demo sürümü",
      body: "RoboTakas demo sürümünde: hesabın ve ilanların her zaman silebileceğin gerçek veridir.",
      published_at: Time.current,
    )

    puts "Örnek veri oluşturuldu: #{Conversation.count} konuşma, #{Announcement.count} duyuru."
  end

  desc "Demo hazırlığını salt okunur kontrol eder (veriyi değiştirmez)"
  task check: :environment do
    def line(ok, message)
      puts "#{ok ? 'OK   ' : 'UYARI'}  #{message}"
    end

    admin = User.where(role: "admin").order(:id).first
    line(admin.present?, "admin hesabı: #{admin ? admin.email : 'yok'}")

    demo_users = User.where("email LIKE 'demo%@robotakas.test'").count
    line(demo_users >= 6, "demo kullanıcı: #{demo_users}")

    category_count = Category.count
    root_count = Category.roots.count
    part_count = Part.count
    approved_part_count = Part.approved.count
    active_listing_count = Listing.active.count
    total_listing_count = Listing.count
    pending_part_count = Part.where(status: "pending").count

    line(category_count >= 30, "kategori: #{category_count} (kök: #{root_count})")
    line(approved_part_count >= 20, "onaylı parça: #{approved_part_count} (toplam: #{part_count})")
    line(active_listing_count >= 10, "aktif ilan: #{active_listing_count} (toplam: #{total_listing_count})")
    line(pending_part_count >= 1, "bekleyen parça önerisi: #{pending_part_count}")

    missing_blobs = 0
    ActiveStorage::Blob.find_each do |blob|
      exists = blob.service.exist?(blob.key)
      missing_blobs += 1 unless exists
    rescue StandardError
      missing_blobs += 1
    end
    line(missing_blobs.zero?, "dosyası eksik Active Storage blob'u: #{missing_blobs}")

    duplicate_titles = Listing.group(:title).having("COUNT(*) > 1").count
    line(duplicate_titles.empty?, "tekrar eden ilan başlığı: #{duplicate_titles.size}")

    def repeated_words(text)
      words = text.to_s.split(/\s+/)
      words.each_cons(2).select { |a, b| a.casecmp?(b) }.map(&:first).uniq
    end

    dirty_titles = Listing.pluck(:title).count { |title| repeated_words(title).any? }
    dirty_parts = Part.pluck(:name).count { |name| repeated_words(name).any? }
    line(
      (dirty_titles + dirty_parts).zero?,
      "art arda tekrar eden sözcük (ilan başlığı/parça adı): #{dirty_titles + dirty_parts}",
    )

    conversation_count = Conversation.count
    line(conversation_count >= 2, "konuşma: #{conversation_count}")
    announcement_count = Announcement.count
    line(announcement_count >= 1, "duyuru: #{announcement_count}")

    db_path = ActiveRecord::Base.connection_db_config.database
    db_path = File.expand_path(db_path, Rails.root) unless db_path.start_with?("/")
    line(File.exist?(db_path), "veritabanı: #{db_path}")
  end
end
