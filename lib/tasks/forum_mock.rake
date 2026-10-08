namespace :forum do
  desc "Forum için örnek kullanıcı, konu, cevap ve beğeni verisi oluşturur (idempotent)"
  task seed_mock: :environment do
    abort "forum:seed_mock production ortamında çalıştırılamaz." if Rails.env.production?

    summary = ForumMockSeeder.seed!

    puts "Forum mock seed tamamlandı."
    puts "Bölüm: +#{summary[:boards_created]} · Kullanıcı: +#{summary[:users_created]} · Konu: +#{summary[:topics_created].size} · Cevap: +#{summary[:posts_created]} · Beğeni: +#{summary[:likes_created]} · Çözüm: #{summary[:solved]}"

    if summary[:topics_created].any?
      puts "Oluşturulan konular:"
      summary[:topics_created].each { |title| puts "  + #{title}" }
    end

    if summary[:topics_skipped].any?
      puts "Atlanan konular (zaten vardı):"
      summary[:topics_skipped].each { |title| puts "  = #{title}" }
    end

    puts "Okundu işaretlenen bildirim: #{summary[:notifications_marked_read]}"
  end

  desc "Test User 1'in açtığı forum konularını siler (varsayılan: dry-run; gerçek silme için CONFIRM=yes)"
  task purge_test_topics: :environment do
    abort "forum:purge_test_topics production ortamında çalıştırılamaz." if Rails.env.production?

    matches = User.where(full_name: "Test User 1")

    if matches.empty?
      abort "Test User 1 bulunamadı. Hiçbir şey değiştirilmedi."
    end

    if matches.count > 1
      puts "Birden fazla 'Test User 1' bulundu:"
      matches.each { |user| puts "  ##{user.id} · #{user.email}" }
      abort "Belirsizlik nedeniyle işlem yapılmadı."
    end

    user = matches.first
    topics = ForumTopic.where(user: user).includes(:forum_board).order(:id)
    topic_ids = topics.pluck(:id)
    replies_elsewhere = ForumPost.where(user: user).where.not(forum_topic_id: topic_ids).count

    puts "Test User 1: ##{user.id} · #{user.email}"
    puts "Açtığı konu: #{topics.count}"
    topics.each do |topic|
      puts "  ##{topic.id} · #{topic.forum_board&.name} · #{topic.title} (#{topic.posts_count} cevap)"
    end
    puts "Başka konularda yazdığı cevap (silinmeyecek, yalnız rapor): #{replies_elsewhere}"

    if ENV["CONFIRM"] != "yes"
      puts "DRY-RUN: hiçbir şey silinmedi."
      puts "Gerçek silme için: CONFIRM=yes bin/rails forum:purge_test_topics"
      next
    end

    before = { topics: ForumTopic.count, posts: ForumPost.count, notifications: Notification.count }

    topic_ids.each { |id| ForumTopic.find_by(id: id)&.destroy }
    ForumBoard.find_each(&:recalculate_counters!)
    Notification.where(forum_topic_id: topic_ids).delete_all

    after = { topics: ForumTopic.count, posts: ForumPost.count, notifications: Notification.count }

    puts "Silindi: #{before[:topics] - after[:topics]} konu, #{before[:posts] - after[:posts]} cevap."
    puts "Bildirim: #{before[:notifications]} → #{after[:notifications]}"
    puts "Kalan konu: #{after[:topics]} (bölüm sayaçları yeniden hesaplandı)"
  end
end
