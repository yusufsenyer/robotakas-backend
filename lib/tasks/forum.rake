namespace :forum do
  desc "Forum bölümlerini ekler (idempotent, mevcut kayıtlara dokunmaz)"
  task seed_boards: :environment do
    created = ForumSeeder.seed_boards!

    if created.zero?
      puts "Forum bölümleri zaten mevcut, hiçbir şey eklenmedi. Toplam: #{ForumBoard.count}."
    else
      puts "#{created} forum bölümü eklendi. Toplam: #{ForumBoard.count}."
    end
  end
end
