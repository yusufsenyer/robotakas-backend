namespace :data do
  desc "Demo/test hesaplarını sertleştirir. Varsayılan DRY-RUN; uygulamak için CONFIRM=yes"
  task harden: :environment do
    old_admin_email = ENV["OLD_ADMIN_EMAIL"].to_s.strip.downcase
    demo_password = ENV["DEMO_PASSWORD"].to_s

    old_admin = old_admin_email.present? ? User.find_by(email: old_admin_email) : nil
    demo_scope = User.where("email LIKE ?", "%@robotakas.test").order(:id)

    puts "== data:harden DRY-RUN =="

    if old_admin_email.blank?
      puts "OLD_ADMIN_EMAIL verilmedi: eski admin düşürme adımı atlanacak."
    elsif old_admin.nil?
      puts "OLD_ADMIN_EMAIL=#{EmailMasker.call(old_admin_email)} ile hesap bulunamadı."
    else
      puts "Eski admin: #{EmailMasker.call(old_admin.email)} " \
           "(rol #{old_admin.role} → user, parola kriptografik rastgele yapılacak)"
    end

    if demo_password.empty?
      puts "DEMO_PASSWORD verilmedi: @robotakas.test parola güncellemesi atlanacak."
      demo_password = nil
    elsif demo_password.length < 12
      puts "DEMO_PASSWORD 12 karakterden kısa: @robotakas.test parola güncellemesi atlanacak."
      demo_password = nil
    else
      puts "@robotakas.test kullanıcı sayısı: #{demo_scope.count}"
      demo_scope.each { |user| puts "  - #{EmailMasker.call(user.email)}" }
    end

    if ENV["CONFIRM"] != "yes"
      puts "DRY-RUN: hiçbir şey değiştirilmedi."
      puts "Uygulamak için: CONFIRM=yes bin/rails data:harden"
      next
    end

    changes = 0

    if old_admin
      random = SecureRandom.urlsafe_base64(24)
      old_admin.update!(role: "user", password: random)
      changes += 1
    end

    if demo_password
      demo_scope.find_each do |user|
        user.update!(password: demo_password)
        changes += 1
      end
    end

    # Parola ve hash asla yazılmaz.
    puts "Uygulandı: #{changes} hesap güncellendi."
  end
end
