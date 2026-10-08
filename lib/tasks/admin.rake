namespace :admin do
  desc "ENV[ADMIN_EMAIL] + ENV[ADMIN_PASSWORD] (min 12 karakter) ile admin oluşturur/günceller (idempotent)"
  task create: :environment do
    email = ENV["ADMIN_EMAIL"].to_s.strip.downcase
    password = ENV["ADMIN_PASSWORD"].to_s

    abort "ADMIN_EMAIL ortam değişkeni gerekli." if email.empty?
    abort "ADMIN_PASSWORD en az 12 karakter olmalı." if password.length < 12

    user = User.find_by(email: email)

    if user
      user.update!(password: password, role: "admin")
      action = "güncellendi"
    else
      User.create!(
        full_name: ENV.fetch("ADMIN_NAME", "RoboTakas Yönetici"),
        email: email,
        password: password,
        city: ENV.fetch("ADMIN_CITY", "Ankara"),
        role: "admin",
      )
      action = "oluşturuldu"
    end

    # Parola ve hash asla yazılmaz; e-posta maskeli.
    puts "Admin #{action}: #{EmailMasker.call(email)}"
  end
end
