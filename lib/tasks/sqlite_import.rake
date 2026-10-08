namespace :db do
  desc "SQLite anlık kopyasından (SOURCE_SQLITE) Postgres'e veri aktarır. Hedef boş olmalı."
  task import_from_sqlite: :environment do
    source = ENV["SOURCE_SQLITE"].to_s
    abort "SOURCE_SQLITE gerekli (anlık kopya yolu)." if source.empty?
    abort "Kaynak dosya bulunamadı: #{source}" unless File.exist?(source)

    unless system("command -v sqlite3 > /dev/null 2>&1")
      abort "sqlite3 CLI bulunamadı (kaynağı okumak için gerekli)."
    end

    conn = ActiveRecord::Base.connection
    abort "Hedef Postgres değil (adapter=#{conn.adapter_name}); import iptal." unless conn.adapter_name == "PostgreSQL"

    %w[users categories].each do |table|
      next unless conn.table_exists?(table)
      if conn.select_value("SELECT COUNT(*) FROM #{conn.quote_table_name(table)}").to_i.positive?
        abort "Hedef DB boş değil (#{table} dolu); import iptal edildi."
      end
    end

    json_types = [ ActiveRecord::Type::Json, ActiveRecord::Type::Serialized ].freeze
    json_column = lambda do |model, column|
      type = model.attribute_types[column]
      json_types.any? { |klass| type.is_a?(klass) } || type.class.name.to_s.include?("Json")
    end

    read_source = lambda do |table|
      out = IO.popen([ "sqlite3", "-readonly", "-json", source, "SELECT * FROM \"#{table}\"" ], &:read)
      abort "sqlite3 okunamadı (#{table}); çıkış kodu #{$?.exitstatus}" unless $?.success?
      out.to_s.strip.empty? ? [] : JSON.parse(out)
    end

    prepare = lambda do |model, rows|
      rows.map do |row|
        row.each_with_object({}) do |(column, value), memo|
          memo[column] =
            if value.is_a?(String) && json_column.call(model, column)
              JSON.parse(value)
            else
              value
            end
        end
      end
    end

    order_categories = lambda do |rows|
      by_id = rows.index_by { |row| row["id"] }
      depth = lambda do |row|
        parent = row["parent_id"]
        parent.nil? ? 0 : depth.call(by_id.fetch(parent)) + 1
      end
      rows.sort_by { |row| [ depth.call(row), row["id"] ] }
    end

    import_order = [
      [ "users", User ],
      [ "categories", Category ],
      [ "parts", Part ],
      [ "listings", Listing ],
      [ "listing_compatible_categories", ListingCompatibleCategory ],
      [ "favorites", Favorite ],
      [ "site_stats", SiteStat ],
      [ "saved_searches", SavedSearch ],
      [ "conversations", Conversation ],
      [ "messages", Message ],
      [ "reports", Report ],
      [ "announcements", Announcement ],
      [ "announcement_reads", AnnouncementRead ],
      [ "forum_boards", ForumBoard ],
      [ "forum_topics", ForumTopic ],
      [ "forum_posts", ForumPost ],
      [ "forum_likes", ForumLike ],
      [ "notifications", Notification ],
      [ "active_storage_blobs", ActiveStorage::Blob ],
      [ "active_storage_attachments", ActiveStorage::Attachment ],
      [ "active_storage_variant_records", ActiveStorage::VariantRecord ]
    ]

    puts "== db:import_from_sqlite =="

    counts = {}
    ActiveRecord::Base.transaction do
      import_order.each do |table, model|
        rows = read_source.call(table)
        rows = order_categories.call(rows) if table == "categories"
        rows = prepare.call(model, rows)

        model.insert_all!(rows) if rows.any?
        conn.reset_pk_sequence!(table) if rows.any?

        counts[table] = [ rows.size, conn.select_value("SELECT COUNT(*) FROM #{conn.quote_table_name(table)}").to_i ]
        puts format("%-32s kaynak=%-4d hedef=%-4d", table, counts[table][0], counts[table][1])
      end

      mismatched = counts.select { |_table, (from, to)| from != to }
      abort "Satır sayısı uyuşmuyor: #{mismatched.inspect}" if mismatched.any?
    end

    puts "Tamamlandı: #{counts.values.sum(&:first)} satır aktarıldı."
  end
end
