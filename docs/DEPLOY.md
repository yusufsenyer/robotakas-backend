# RoboTakas Backend — Deployment (Render + Supabase)

## 0. Özet

- **Yerel geliştirme ve test: SQLite** (`storage/development.sqlite3`, `storage/test.sqlite3`).
- **Production: PostgreSQL (Supabase)** — tek veritabanı.
- **Dosya depolama: Supabase Storage (S3 uyumlu, private bucket)** — Active Storage imzalı URL kullanır.
- **Şifreleme anahtarı: `SECRET_KEY_BASE` env**; `config/master.key` ve `config/credentials.yml.enc` **kaldırıldı**, kullanılmaz.
- **Arka plan işleri/cache/cable: in-process** (`:async` Active Job, `:memory_store`). Ayrı worker/cache/queue DB yok (ücretsiz tek servis).
- Deploy: **Render free web service (Docker)**, Frankfurt, health check `/up`.

## 1. Akış

```
Frontend (Next.js)  ->  Render web (Docker, bin/render-start)
                              |            \
                     Supabase Postgres      Supabase Storage (S3, private)
                     (session pooler 5432)   (imzalı URL ile indirme)
```

## 2. Ortam değişkenleri (değer YOK — sadece ad/açıklama/biçim/kaynak)

| Değişken | Açıklama | Örnek biçim | Kaynak |
|---|---|---|---|
| `RAILS_ENV` | Ortam | `production` | render.yaml |
| `RAILS_LOG_LEVEL` | Log seviyesi (STDOUT) | `info` | render.yaml |
| `RAILS_MAX_THREADS` | Puma thread + AR pool | `3` | render.yaml |
| `WEB_CONCURRENCY` | Puma worker sayısı | `1` | render.yaml |
| `PORT` | Dinlenen port | `10000` | Render otomatik |
| `SECRET_KEY_BASE` | Rails secret | long random | `bin/rails secret` / Render secret |
| `DATABASE_URL` | Supabase **session pooler** | `postgresql://postgres.<ref>:<pwd>@aws-0-<region>.pooler.supabase.com:5432/postgres?sslmode=require` | Supabase → Database → Connection string (Session pooler) |
| `SUPABASE_S3_ENDPOINT` | Storage S3 endpoint | `https://<ref>.supabase.co/storage/v1/s3` | Supabase → Storage → S3 |
| `SUPABASE_S3_REGION` | Proje bölgesi | `eu-central-1` | Supabase proje bölgesi |
| `SUPABASE_S3_BUCKET` | Private bucket adı | `robotakas` | Supabase → Storage |
| `SUPABASE_S3_ACCESS_KEY_ID` | S3 access key | `...` | Supabase → Storage → S3 access keys |
| `SUPABASE_S3_SECRET_ACCESS_KEY` | S3 secret key | `...` | Supabase → Storage → S3 access keys |
| `ALLOWED_HOSTS` | İzinli host'lar (virgüllü, opsiyonel) | `api.robotakas.com` | Sizin alan adınız |
| `SITE_HOST` | Mailer link host'u | `api.robotakas.com` | Sizin alan adınız |
| `CORS_ORIGINS` | (Opsiyonel) ayrı origin'ler | `https://robotakas.com` | Sadece cross-origin gerekiyorsa |

Otomatik gelenler: `RENDER_EXTERNAL_HOSTNAME` (Render sağlar; `config.hosts`'a eklenir).

**Kritik:** Production'da Active Storage eager-load sırasında S3 servisini kurar. `SUPABASE_S3_*` değerleri eksikse uygulama **boot edemez**.

## 3. Supabase kurulumu

1. Yeni proje oluştur; bölge olarak Render ile yakın olanı seç (örn. **Frankfurt / eu-central-1**).
2. **PostgreSQL bağlantısı:** Project Settings → Database → Connection string → **Session pooler** (host `...pooler.supabase.com`, **port 5432**).
   - ✅ Session pooler (5432): prepared statement ve advisory lock destekler, ek ayar gerekmez.
   - ❌ Transaction pooler (6543): kullanma. Gerekirse `config/database.yml` içindeki `prepared_statements: false` ve `advisory_locks: false` satırlarını aç.
3. `DATABASE_URL` sonuna `?sslmode=require` ekle.
4. **Storage:** yeni bir bucket oluştur ve **Private** yap. Public URL kullanılmaz; Active Storage imzalı (süreli) URL üretir.
5. **S3 anahtarları:** Storage → S3 access keys → yeni access key oluştur; Access key ID ve Secret'ı `SUPABASE_S3_*` olarak kaydet.

## 4. Render kurulumu

1. Render → **New → Blueprint** → `robotakas-backend` reposunu seç. `render.yaml` algılanır.
2. Servis ayarları (render.yaml'dan): `runtime: docker`, `plan: free`, `region: frankfurt`, `dockerfilePath: ./Dockerfile`, `dockerCommand: bin/render-start`, `healthCheckPath: /up`, `autoDeploy: false`.
3. `sync: false` işaretli secret'ları panelden gir (adım 2 tablosu).
4. İlk deploy'u manuel başlat. `bin/render-start` önce `bin/rails db:migrate` çalıştırır, sonra Puma'yı başlatır.

> Neden `db:prepare` değil? `db:prepare` boş veritabanında **seed** çalıştırabilir. `db:migrate` yalnızca şemayı kurar.

## 5. İlk deploy sonrası kontrol listesi

- [ ] `GET /up` → `200` (Render health check de bunu kullanır)
- [ ] `GET /api/v1/health` → `200`
- [ ] Admin ile giriş: `POST /api/v1/auth/login`
- [ ] `GET /api/v1/listings` → ilanlar geliyor
- [ ] Dosya yükleme (ilan fotoğrafı) + `GET` ile görüntüleme (imzalı URL) çalışıyor
- [ ] `RAILS_LOG_LEVEL=info` ile loglar STDOUT'a akıyor
- [ ] `GET /up` HTTP (SSL'siz) istekte 301 yerine 200 dönüyor (health check muaf)

## 6. Soğuk başlangıç

Render **free** planı, hareketsizlikten sonra servisi uyku moduna alır. Uyandıran ilk istek **~1 dakika** sürebilir. Health check `/up` ısınma için kullanılabilir. Ücretsiz planda kalıcı disk yoktur; bu yüzden dosyalar Supabase Storage'da tutulur.

## 7. Sorun giderme

| Belirti | Olası neden | Çözüm |
|---|---|---|
| Deploy'da `MissingRegion` / S3 init hatası | `SUPABASE_S3_*` eksik | Tüm Supabase S3 env'lerini gir |
| `database configuration does not specify adapter` | `DATABASE_URL` yok | `DATABASE_URL` (session pooler + `sslmode=require`) gir |
| `SSL ... required` bağlantı hatası | `sslmode` eksik | URL'e `?sslmode=require` ekle |
| `prepared statement ... already exists` | transaction pooler (6543) | Session pooler (5432) kullan |
| `/up` 301 dönüyor | SSL redirect health check'e uygulanıyor | `/up` muaf (production.rb); host/port doğru mu kontrol et |
| `Blocked host` (host authorization) | host izinli değil | `ALLOWED_HOSTS` veya Render host otomatik eklenir; kontrol et |
| Dosyalar görünmüyor | bucket private + yanlış servis | `active_storage.service = :supabase`, imzalı URL beklenir |
| Cold start gecikmesi | free plan uykusu | Normaldir (~1 dk); health check/ping kullan |
| `Scoped order is ignored` uyarısı | `find_each` + `order` | Bilgi amaçlı; görevler `each` kullanır |

## 8. Veri taşıma runbook (SQLite → Supabase)

> Bu adımlar **production'a yazar**. Yalnızca onaydan sonra, kendi terminalinizde çalıştırın. Secret'ları sohbete yapıştırmayın.

### 8.0 Anlık kopya (kaynak)

```bash
mkdir -p /tmp/rt
sqlite3 storage/development.sqlite3 ".backup '/tmp/rt/dev_snapshot.sqlite3'"
```

### 8.1 Env (terminalde)

```bash
export SECRET_KEY_BASE="$(openssl rand -hex 64)"   # veya dev'de: bin/rails secret
export RAILS_ENV=production
export DATABASE_URL="postgresql://postgres.<ref>:<pwd>@aws-0-<region>.pooler.supabase.com:5432/postgres?sslmode=require"
export SUPABASE_S3_ENDPOINT="https://<ref>.supabase.co/storage/v1/s3"
export SUPABASE_S3_REGION="<region>"
export SUPABASE_S3_BUCKET="<private-bucket>"
export SUPABASE_S3_ACCESS_KEY_ID="..."          # terminalde girin
export SUPABASE_S3_SECRET_ACCESS_KEY="..."
export SITE_HOST="<render-host>"
export ALLOWED_HOSTS="<render-host>"
```

### 8.2 Ön kontrol (her production komutundan ÖNCE çalıştırın)

```bash
# A) DATABASE_URL session pooler mı? (host pooler.supabase.com ve port 5432; 6543 ise DUR)
ruby -ruri -e 'u=URI(ENV["DATABASE_URL"].to_s); ok=u.host.to_s.end_with?("pooler.supabase.com") && u.port==5432; warn "host=#{u.host} port=#{u.port}"; abort "HATA: session pooler (pooler.supabase.com:5432) gerekli." unless ok; puts "OK: session pooler"'

# B) Hedef veritabanı boş mu? (users/categories yok ya da 0 satır; secret yazdırmaz)
bin/rails runner '%w[users categories].each { |t| c=ActiveRecord::Base.connection; n=c.table_exists?(t) ? c.select_value("SELECT COUNT(*) FROM #{t}").to_i : 0; puts "#{t}=#{n}"; abort "HATA: hedef #{t} dolu; import iptal." if n.positive? }'
```

### 8.3 Adımlar

```bash
bin/rails db:migrate                                                        # şema
SOURCE_SQLITE=/tmp/rt/dev_snapshot.sqlite3 bin/rails db:import_from_sqlite  # veri (hedef boş olmalı)
bin/rails storage:upload_to_supabase                                        # blob dosyasını S3'e yükle
OLD_ADMIN_EMAIL=admin@robotakas.test bin/rails data:harden                  # önce DRY-RUN
CONFIRM=yes OLD_ADMIN_EMAIL=admin@robotakas.test bin/rails data:harden
ADMIN_EMAIL=admin@robotakas.com ADMIN_PASSWORD='<min12>' bin/rails admin:create
```

Her adımdan sonra çıktıyı kontrol edin; hiçbir adım secret yazdırmaz.

### 8.4 Geri alma (import yarım kaldıysa)

`db:import_from_sqlite` **tek transaction** içinde çalışır: bir hata veya satır sayısı uyuşmazlığında **tüm değişiklikler geri alınır**, hedef veritabanı boş kalır. Önce doğrulayın:

```bash
bin/rails runner '%w[users categories].each { |t| c=ActiveRecord::Base.connection; n=c.table_exists?(t) ? c.select_value("SELECT COUNT(*) FROM #{t}").to_i : 0; puts "#{t}=#{n}" }'
```

Hedef yine de kirli görünüyorsa (örn. transaction öncesi eski bir deneme ya da `db:migrate` sonrası elle değişiklik) iki seçenek:

- **(A) En güvenli — yeni/temiz Supabase projesi (veya yeni database):**
  Yeni proje oluşturup `DATABASE_URL`'i ona çevirin, sonra 8.3'ü baştan çalıştırın.
  *Neden:* `public` şemasında hiç kalıntı kalmaz; DROP işlemlerinin paylaşılan nesnelere (extension vb.) dokunma riski yoktur.

- **(B) Aynı projeyi kullanmak zorundaysanız — `public` şemasını sıfırla:**
  ```sql
  DROP SCHEMA public CASCADE;
  CREATE SCHEMA public;
  ```
  sonra `bin/rails db:migrate`.
  *Risk:* `public` şemadaki **her şey** (varsa `pg_trgm` gibi extension'lar dahil) silinir; gerekirse `CREATE EXTENSION ...` ile geri eklenmelidir. Bu yüzden (A) önerilir.

  Yalnızca uygulama tablolarını hedefli silmek isterseniz:
  ```sql
  DROP TABLE IF EXISTS active_storage_variant_records, active_storage_attachments, active_storage_blobs,
    notifications, forum_likes, forum_posts, forum_topics, forum_boards, announcement_reads, announcements,
    reports, messages, conversations, saved_searches, site_stats, favorites,
    listing_compatible_categories, listings, parts, categories, users CASCADE;
  ```
  sonra `bin/rails db:migrate`.

> **Yasak:** Production veritabanına `rails test`, `db:test:prepare`, `db:drop`, `db:schema:load` **çalıştırmayın**.

## 9. Active Storage blob taşıma

Dev'de dosyalar diskte `storage/<key[0,2]>/<key[2,2]>/<key>` altındadır. Import sonrası blob'lar `service_name=local` olarak gelir. `storage:upload_to_supabase` bunları **aynı key** ile Supabase bucket'ına yükler ve `service_name`'i `supabase` yapar. S3 anahtarları env'den gelir.

## 10. Dockerfile notları (statik inceleme — değiştirilmedi)

- **Öneri:** Base imajdaki apt listesinden `sqlite3` **kaldırılabilir** (production artık PostgreSQL kullanır). `libvips` gerekli (image variants).
- `pg` gem, `Gemfile.lock`'ta `pg (1.7.0-x86_64-linux)` önceden derlenmiş olarak çözülür; bu platformda ek libpq-dev gerekmez. Farklı bir platformda kaynak derleme gerekirse build aşamasına `libpq-dev` eklenmelidir.
- `BUNDLE_WITHOUT="development"` test grubunu (sqlite3, debug, brakeman, rubocop) imaja dahil eder; `development:test` yapılırsa imaj küçülür (opsiyonel).
- `CMD` Thruster'dır; Render'da `dockerCommand: bin/render-start` ile geçersiz kılınır.
- Docker build bu ortamda denenemedi (docker daemon yok); yukarıdakiler statik incelemedir.
