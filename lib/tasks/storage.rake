namespace :storage do
  desc "service_name=local blob'larını Supabase (S3) bucket'ına aynı key ile yükler ve service_name=supabase yapar"
  task upload_to_supabase: :environment do
    unless Rails.application.config.active_storage.service.to_sym == :supabase
      abort "active_storage.service :supabase olmalı (RAILS_ENV=production ve SUPABASE_S3_* env gerekir)."
    end

    service = ActiveStorage::Blob.services.fetch(:supabase)
    source_root = Rails.root.join("storage")
    scope = ActiveStorage::Blob.where(service_name: "local")

    if scope.none?
      puts "Yüklenecek blob yok (service_name=local)."
      next
    end

    scope.find_each do |blob|
      path = source_root.join(blob.key[0, 2], blob.key[2, 2], blob.key)
      abort "Dosya bulunamadı: #{path}" unless File.exist?(path)

      File.open(path, "rb") do |io|
        service.upload(
          blob.key, io,
          checksum: blob.checksum,
          filename: blob.filename.to_s,
          content_type: blob.content_type,
          disposition: blob.disposition,
        )
      end
      blob.update_columns(service_name: "supabase")
      puts "Yüklendi: ##{blob.id} · #{blob.filename}"
    end

    puts "Tamamlandı: #{scope.count} blob Supabase'e yüklendi."
  end
end
