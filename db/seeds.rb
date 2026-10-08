# RoboTakas seed verisi. Idempotent: veritabanı boş değilse hiçbir şey yapmaz.
# Mevcut veriyi asla silmez ya da sıfırlamaz.
#
# Üretimde demo admin/kullanıcıları (sabit parola) oluşturmamak için varsayılan
# olarak kapalıdır. Bilinçli çalıştırma yalnız ALLOW_DEMO_SEED=yes ile mümkündür.
if Rails.env.production? && ENV["ALLOW_DEMO_SEED"] != "yes"
  abort "db/seeds.rb demo/örnek hesaplar oluşturur ve production'da çalıştırılmamalıdır. " \
        "Bilinçli çalıştırma için: ALLOW_DEMO_SEED=yes bin/rails db:seed"
end

return if Category.exists?

# --- Kategori yapısı (1. seviye: yarışma, 2. seviye: parça türü) ---

LEAF_TYPES = {
  "Kontrol Kartı" => [ "kontrol-karti", "CircuitBoard" ],
  "Motor" => [ "motor", "Cog" ],
  "Motor Sürücü" => [ "motor-surucu", "Cpu" ],
  "Sensör" => [ "sensor", "ScanLine" ],
  "Batarya ve Şarj" => [ "batarya-ve-sarj", "BatteryCharging" ],
  "Şasi ve Mekanik" => [ "sasi-ve-mekanik", "Wrench" ],
  "Tekerlek" => [ "tekerlek", "Disc3" ],
  "Kablo ve Sarf" => [ "kablo-ve-sarf", "Cable" ],
  "Komple Robot / Kit" => [ "komple-robot-kit", "Box" ]
}.freeze

ALL_TYPES = LEAF_TYPES.keys

ROOTS = [
  { name: "Mini Sumo", slug: "mini-sumo", icon: "Bot", types: ALL_TYPES },
  { name: "Çizgi İzleyen (Temel Seviye)", slug: "cizgi-izleyen-temel-seviye", icon: "Activity", types: ALL_TYPES },
  { name: "Hızlı Çizgi İzleyen", slug: "hizli-cizgi-izleyen", icon: "Gauge", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Tekerlek Komple\ Robot\ /\ Kit] },
  { name: "Labirent Ustası", slug: "labirent-ustasi", icon: "Waypoints", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Tekerlek Komple\ Robot\ /\ Kit] },
  { name: "Tozkoparan Robot", slug: "tozkoparan-robot", icon: "Wind", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Tekerlek Komple\ Robot\ /\ Kit] },
  { name: "Yumurta Toplama", slug: "yumurta-toplama", icon: "Box", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Komple\ Robot\ /\ Kit] },
  { name: "Tasarla-Çalıştır", slug: "tasarla-calistir", icon: "Cog", types: ALL_TYPES },
  { name: "Endüstriyel Robotik Kol", slug: "endustriyel-robotik-kol", icon: "Armchair", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Komple\ Robot\ /\ Kit] },
  { name: "İnsansız Hava Aracı (Mini Drone)", slug: "insansiz-hava-araci-mini-drone", icon: "Plane", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Komple\ Robot\ /\ Kit] },
  { name: "RC Sabit Kanat Uçak", slug: "rc-sabit-kanat-ucak", icon: "Send", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Komple\ Robot\ /\ Kit] },
  { name: "Su Altı Robot", slug: "su-alti-robot", icon: "Waves", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Kablo\ ve\ Sarf Komple\ Robot\ /\ Kit] },
  { name: "Su Üstü Robot", slug: "su-ustu-robot", icon: "Ship", types: %w[Kontrol\ Kartı Motor Motor\ Sürücü Sensör Batarya\ ve\ Şarj Şasi\ ve\ Mekanik Komple\ Robot\ /\ Kit] },
  { name: "Otonom Araç", slug: "otonom-arac", icon: "Car", types: ALL_TYPES },
  { name: "Serbest Proje", slug: "serbest-proje", icon: "Lightbulb", types: ALL_TYPES },
  { name: "Siber Güvenlik", slug: "siber-guvenlik", icon: "ShieldCheck", types: %w[Kontrol\ Kartı Sensör Kablo\ ve\ Sarf Komple\ Robot\ /\ Kit] }
].freeze

CATS = {}
ROOTS.each_with_index do |root, i|
  root_cat = Category.create!(
    name: root[:name],
    slug: root[:slug],
    icon_key: root[:icon],
    position: i,
  )
  CATS[root[:slug]] = root_cat

  root[:types].each_with_index do |type_name, j|
    short_slug, icon = LEAF_TYPES.fetch(type_name)
    leaf = Category.create!(
      parent: root_cat,
      name: type_name,
      slug: "#{root[:slug]}-#{short_slug}",
      icon_key: icon,
      position: j,
    )
    CATS["#{root[:slug]}/#{short_slug}"] = leaf
  end
end

def leaf(root_slug, type_name)
  short_slug, = LEAF_TYPES.fetch(type_name)
  CATS["#{root_slug}/#{short_slug}"]
end

# --- Parçalar (hepsi onaylı, model numaralı) ---

PARTS = [
  # code, name, brand, root, leaf, specs, description
  [ "ARDUINO NANO", "Arduino Nano (klon)", "Arduino (klon)", "cizgi-izleyen-temel-seviye", "Kontrol Kartı",
    [ { label: "Mikrodenetleyici", value: "ATmega328P" }, { label: "Çalışma gerilimi", value: "5V" }, { label: "Saat hızı", value: "16 MHz" } ],
    "Kompakt Arduino klonu. Çizgi izleyen ve sumo projelerinde standart kontrol kartı." ],
  [ "ARDUINO UNO R3", "Arduino Uno R3", "Arduino", "tozkoparan-robot", "Kontrol Kartı",
    [ { label: "Mikrodenetleyici", value: "ATmega328P" }, { label: "Çalışma gerilimi", value: "5V" }, { label: "Saat hızı", value: "16 MHz" } ],
    nil ],
  [ "ARDUINO MEGA 2560", "Arduino Mega 2560", "Arduino", "yumurta-toplama", "Kontrol Kartı",
    [ { label: "Mikrodenetleyici", value: "ATmega2560" }, { label: "Çalışma gerilimi", value: "5V" } ],
    "Çok sayıda giriş-çıkış gerektiren projeler için." ],
  [ "ESP32", "ESP32 Geliştirme Kartı", "Espressif", "otonom-arac", "Kontrol Kartı",
    [ { label: "İşlemci", value: "Çift çekirdekli" }, { label: "Bağlantı", value: "Wi-Fi + Bluetooth" } ],
    nil ],
  [ "ESP32-CAM", "ESP32-CAM", "Espressif", "serbest-proje", "Kontrol Kartı",
    [ { label: "Bağlantı", value: "Wi-Fi" }, { label: "Kamera", value: "Dahili" } ],
    nil ],
  [ "STM32F103C8T6", "STM32F103C8T6 (Blue Pill)", "STMicroelectronics", "hizli-cizgi-izleyen", "Kontrol Kartı",
    [ { label: "Çekirdek", value: "ARM Cortex-M3" }, { label: "Saat hızı", value: "72 MHz" } ],
    nil ],
  [ "TEENSY 4.0", "Teensy 4.0", "PJRC", "hizli-cizgi-izleyen", "Kontrol Kartı",
    [ { label: "Çekirdek", value: "ARM Cortex-M7" }, { label: "Saat hızı", value: "600 MHz" } ],
    nil ],
  [ "RASPBERRY PI 5", "Raspberry Pi 5", "Raspberry Pi", "otonom-arac", "Kontrol Kartı",
    [ { label: "İşlemci", value: "4 çekirdekli ARM Cortex-A76" } ],
    nil ],
  [ "TB6612FNG", "TB6612FNG Çift Motor Sürücü", "Toshiba", "mini-sumo", "Motor Sürücü",
    [ { label: "Kanal", value: "2" }, { label: "Akım", value: "Kanal başına 1.2A sürekli, 3.2A tepe" }, { label: "Gerilim", value: "2.5–13.5V" } ],
    "Hafif ve verimli çift motor sürücü. Sumo ve çizgi izleyenlerde standart." ],
  [ "L298N", "L298N Çift Motor Sürücü", "STMicroelectronics", "cizgi-izleyen-temel-seviye", "Motor Sürücü",
    [ { label: "Kanal", value: "2" }, { label: "Akım", value: "Kanal başına 2A" } ],
    nil ],
  [ "DRV8825", "DRV8825 Step Motor Sürücü", "Texas Instruments", "endustriyel-robotik-kol", "Motor Sürücü",
    [ { label: "Tip", value: "Step motor sürücü" } ],
    nil ],
  [ "A4988", "A4988 Step Motor Sürücü", "Allegro", "endustriyel-robotik-kol", "Motor Sürücü",
    [ { label: "Tip", value: "Step motor sürücü" } ],
    nil ],
  [ "L293D", "L293D Motor Sürücü", "STMicroelectronics", "tasarla-calistir", "Motor Sürücü",
    [ { label: "Kanal", value: "4" }, { label: "Akım", value: "Kanal başına 600mA" } ],
    nil ],
  [ "ULN2003", "ULN2003 Step Motor Sürücü", "Texas Instruments", "endustriyel-robotik-kol", "Motor Sürücü",
    [ { label: "Tip", value: "7 kanal Darlington dizi" } ],
    nil ],
  [ "IRFZ44N", "IRFZ44N MOSFET", "Infineon", "su-alti-robot", "Motor Sürücü",
    [ { label: "Tip", value: "N-kanal MOSFET" } ],
    nil ],
  [ "PCA9685", "PCA9685 16 Kanal PWM Sürücü", "NXP", "endustriyel-robotik-kol", "Motor Sürücü",
    [ { label: "Kanal", value: "16" }, { label: "Arayüz", value: "I2C" } ],
    nil ],
  [ "QTR-8A", "QTR-8A Sensör Dizisi", "Pololu", "cizgi-izleyen-temel-seviye", "Sensör",
    [ { label: "Kanal", value: "8" }, { label: "Tip", value: "Yansıma sensörü" } ],
    "8 kanallı çizgi sensörü. Çizgi izleyen robotların vazgeçilmezi." ],
  [ "QTR-1A", "QTR-1A Sensör", "Pololu", "mini-sumo", "Sensör",
    [ { label: "Kanal", value: "1" }, { label: "Tip", value: "Yansıma sensörü" } ],
    nil ],
  [ "HC-SR04", "HC-SR04 Ultrasonik Mesafe Sensörü", nil, "labirent-ustasi", "Sensör",
    [ { label: "Menzil", value: "2–400 cm" }, { label: "Çalışma gerilimi", value: "5V" } ],
    nil ],
  [ "VL53L0X", "VL53L0X Lazer Mesafe Sensörü", "STMicroelectronics", "labirent-ustasi", "Sensör",
    [ { label: "Tip", value: "ToF lazer" }, { label: "Arayüz", value: "I2C" } ],
    nil ],
  [ "MPU6050", "MPU6050 IMU", "InvenSense", "otonom-arac", "Sensör",
    [ { label: "Eksen", value: "3 eksen jiroskop + ivmeölçer" } ],
    nil ],
  [ "MPU9250", "MPU9250 IMU", "InvenSense", "insansiz-hava-araci-mini-drone", "Sensör",
    [ { label: "Eksen", value: "9 eksen (jiroskop + ivmeölçer + manyetometre)" } ],
    nil ],
  [ "BNO055", "BNO055 IMU", "Bosch", "insansiz-hava-araci-mini-drone", "Sensör",
    [ { label: "Eksen", value: "9 eksen IMU" } ],
    nil ],
  [ "N20", "N20 Mikro Redüktörlü Motor", nil, "cizgi-izleyen-temel-seviye", "Motor", [], nil ],
  [ "MG996R", "MG996R Servo Motor", "TowerPro", "yumurta-toplama", "Motor",
    [ { label: "Tip", value: "Metal dişli servo" }, { label: "Gerilim", value: "4.8–7.2V" } ],
    nil ],
  [ "SG90", "SG90 Mikro Servo", "TowerPro", "rc-sabit-kanat-ucak", "Motor",
    [ { label: "Tip", value: "Mikro servo" } ],
    nil ],
  [ "28BYJ-48", "28BYJ-48 Step Motor", nil, "endustriyel-robotik-kol", "Motor",
    [ { label: "Gerilim", value: "5V" } ],
    nil ],
  [ "RZ60S", "RZ60S Rakip Algılama Sensörü", nil, "mini-sumo", "Sensör", [], nil ],
  [ "TCS3200", "TCS3200 Renk Sensörü", "TAOS", "yumurta-toplama", "Sensör",
    [ { label: "Tip", value: "Renk algılama" } ],
    nil ],
  [ "TCS34725", "TCS34725 Renk Sensörü", "AMS", "yumurta-toplama", "Sensör",
    [ { label: "Tip", value: "RGB renk sensörü" } ],
    nil ],
  [ "INA219", "INA219 Akım Sensörü", "Texas Instruments", "su-alti-robot", "Sensör",
    [ { label: "Arayüz", value: "I2C" } ],
    nil ],
  [ "DS18B20", "DS18B20 Sıcaklık Sensörü", "Maxim", "serbest-proje", "Sensör",
    [ { label: "Arayüz", value: "1-Wire" } ],
    nil ],
  [ "DHT22", "DHT22 Sıcaklık ve Nem Sensörü", "Aosong", "serbest-proje", "Sensör",
    [ { label: "Ölçüm", value: "Sıcaklık + nem" } ],
    nil ],
  [ "NRF24L01", "nRF24L01 2.4GHz Modül", "Nordic", "tozkoparan-robot", "Sensör",
    [ { label: "Frekans", value: "2.4 GHz" } ],
    nil ],
  [ "HM-10", "HM-10 Bluetooth Modül", nil, "serbest-proje", "Sensör",
    [ { label: "Tip", value: "BLE modülü" } ],
    nil ],
  [ "LM2596", "LM2596 Buck Dönüştürücü", "Texas Instruments", "su-ustu-robot", "Batarya ve Şarj",
    [ { label: "Tip", value: "Buck (düşürücü) dönüştürücü" } ],
    nil ],
  [ "XL4015", "XL4015 Buck Dönüştürücü (5A)", "XLSEMI", "tasarla-calistir", "Batarya ve Şarj",
    [ { label: "Tip", value: "Buck dönüştürücü" }, { label: "Akım", value: "5A" } ],
    nil ],
  [ "XL6009", "XL6009 Boost Dönüştürücü", "XLSEMI", "serbest-proje", "Batarya ve Şarj",
    [ { label: "Tip", value: "Boost (yükseltici) dönüştürücü" } ],
    nil ]
].freeze

parts = {}
PARTS.each do |code, name, brand, root_slug, leaf_name, specs, description|
  part = Part.create!(
    code: code,
    name: name,
    brand: brand,
    category: leaf(root_slug, leaf_name),
    specs: specs,
    description: description,
    status: "approved",
  )
  parts[code] = part
end

# --- Kullanıcılar ---

USERS = [
  { full_name: "RoboTakas Admin", email: "admin@robotakas.test", password: "Admin1234!", city: "Ankara", team_name: nil, phone: nil, role: "admin" },
  { full_name: "Efe Kaya", email: "demo1@robotakas.test", password: "Demo1234!", city: "Ankara", team_name: "Anka Robotics", phone: "0555 000 00 01", role: "user" },
  { full_name: "Zeynep Demir", email: "demo2@robotakas.test", password: "Demo1234!", city: "İstanbul", team_name: nil, phone: nil, role: "user" },
  { full_name: "Mert Yılmaz", email: "demo3@robotakas.test", password: "Demo1234!", city: "İzmir", team_name: "Ege Mekatronik", phone: "0555 000 00 03", role: "user" },
  { full_name: "Elif Şahin", email: "demo4@robotakas.test", password: "Demo1234!", city: "Bursa", team_name: nil, phone: nil, role: "user" },
  { full_name: "Kerem Çelik", email: "demo5@robotakas.test", password: "Demo1234!", city: "Konya", team_name: "Selçuk Robotik", phone: "0555 000 00 05", role: "user" },
  { full_name: "Selin Arslan", email: "demo6@robotakas.test", password: "Demo1234!", city: "Antalya", team_name: nil, phone: nil, role: "user" }
].freeze

users = USERS.map do |attrs|
  User.create!(attrs)
end

# --- İlanlar (hepsi aktif, fotoğrafsız) ---

LISTINGS = [
  # user, title, description, condition, price, quantity, seasons_used, root, leaf, part_code(nil=genel), city, district, show_phone, compatible_roots, days_ago
  [ 1, "TB6612FNG çift motor sürücü, temiz", "İki sezon sumo robotunda kullandık. Çalışır durumda, bacakları sağlam.", "used", 110, 1, 2, "mini-sumo", "Motor Sürücü", "TB6612FNG", "Ankara", "Yenimahalle", true, [], 3 ],
  [ 2, "TB6612FNG motor sürücü sıfır", "Sıfır, hiç lehimlenmedi. Yedek olarak almıştık.", "new", 170, 2, nil, "mini-sumo", "Motor Sürücü", "TB6612FNG", "İstanbul", "Kadıköy", false, %w[cizgi-izleyen-temel-seviye], 1 ],
  [ 3, "TB6612FNG + N20 set, çizgi izleyen için", "TB6612FNG ve iki adet N20 motoru birlikte veriyorum.", "used", 260, 1, 1, "cizgi-izleyen-temel-seviye", "Motor Sürücü", "TB6612FNG", "İzmir", "Bornova", false, [], 5 ],
  [ 1, "QTR-8A sensör dizisi", "Sekiz kanal çalışıyor, tek kanalda hassasiyet ayarı gerekebilir.", "used", 120, 1, 2, "cizgi-izleyen-temel-seviye", "Sensör", "QTR-8A", "Ankara", "Çankaya", false, [], 2 ],
  [ 4, "QTR-8A sıfır, kutusunda", "Kutusundan çıkardım, hiç kullanılmadı.", "new", 210, 1, nil, "cizgi-izleyen-temel-seviye", "Sensör", "QTR-8A", "Bursa", "Nilüfer", false, [], 6 ],
  [ 5, "QTR-8A klon, test edildi", "Klon ama sorunsuz. Okul takımında denedik.", "used", 90, 2, 1, "cizgi-izleyen-temel-seviye", "Sensör", "QTR-8A", "Konya", "Selçuklu", false, [], 4 ],
  [ 1, "Arduino Nano klon, 3 adet", "Üç adet Nano klonu birlikte satıyorum. İkisi hiç kullanılmadı.", "used", 420, 3, 1, "cizgi-izleyen-temel-seviye", "Kontrol Kartı", "ARDUINO NANO", "Ankara", "Keçiören", true, %w[mini-sumo labirent-ustasi], 7 ],
  [ 6, "Arduino Nano klon sıfır", "Sıfır, USB kablosuyla birlikte.", "new", 180, 1, nil, "cizgi-izleyen-temel-seviye", "Kontrol Kartı", "ARDUINO NANO", "Antalya", "Muratpaşa", false, [], 1 ],
  [ 2, "Arduino Nano + breadboard kabloları", "Nano klon ve bağlantı kabloları. Başlangıç için yeterli.", "used", 160, 1, 1, "cizgi-izleyen-temel-seviye", "Kontrol Kartı", "ARDUINO NANO", "İstanbul", "Beşiktaş", false, [], 9 ],
  [ 3, "Arduino Uno R3 klon", "İki projede kullandım, pinleri sağlam.", "used", 150, 1, 2, "tozkoparan-robot", "Kontrol Kartı", "ARDUINO UNO R3", "İzmir", "Karşıyaka", false, %w[tasarla-calistir], 3 ],
  [ 4, "Arduino Mega 2560 klon", "Yumurta toplama robotumuzda kullandık. Fazla pin var, iş görüyor.", "used", 450, 1, 1, "yumurta-toplama", "Kontrol Kartı", "ARDUINO MEGA 2560", "Bursa", "Osmangazi", false, [], 5 ],
  [ 1, "L298N motor sürücü", "Eski tip ama sağlam. Ağır motorlarda iyi.", "used", 80, 1, 2, "cizgi-izleyen-temel-seviye", "Motor Sürücü", "L298N", "Ankara", "Mamak", false, [], 8 ],
  [ 5, "HC-SR04 ultrasonik sensör, 2 adet", "Labirent robotu için almıştık, ikisi de çalışıyor.", "used", 160, 2, 1, "labirent-ustasi", "Sensör", "HC-SR04", "Konya", "Meram", false, %w[otonom-arac], 6 ],
  [ 6, "VL53L0X lazer mesafe sensörü", "I2C lazer sensör. Kısa mesafede çok hassas.", "new", 240, 1, nil, "labirent-ustasi", "Sensör", "VL53L0X", "Antalya", "Konyaaltı", false, [], 2 ],
  [ 2, "MPU6050 jiroskop", "Denge projesi için almıştık, artık lazım değil.", "used", 90, 1, 1, "otonom-arac", "Sensör", "MPU6050", "İstanbul", "Üsküdar", false, [], 10 ],
  [ 3, "N20 motor 600 RPM, 2 adet", "İki adet N20, aynı devirde. Dişlileri sağlam.", "used", 140, 2, 1, "cizgi-izleyen-temel-seviye", "Motor", "N20", "İzmir", "Konak", false, [], 4 ],
  [ 4, "MG996R servo motor", "Metal dişli, yumurta toplama robotunun tutucusunda kullandık.", "used", 150, 1, 1, "yumurta-toplama", "Motor", "MG996R", "Bursa", "Yıldırım", false, %w[endustriyel-robotik-kol], 7 ],
  [ 1, "SG90 mikro servo, 4 adet", "Dört adet SG90. Uçak projesinde kullanıldı.", "used", 200, 4, 1, "rc-sabit-kanat-ucak", "Motor", "SG90", "Ankara", "Etimesgut", false, [], 5 ],
  [ 5, "ESP32 geliştirme kartı", "Wi-Fi ve Bluetooth'lu. Otonom projede test ettik.", "used", 190, 1, 1, "otonom-arac", "Kontrol Kartı", "ESP32", "Konya", "Karatay", false, %w[serbest-proje], 3 ],
  [ 6, "ESP32-CAM kamera modülü", "Görüntü işleme denemesi için aldık, temiz.", "new", 260, 1, nil, "serbest-proje", "Kontrol Kartı", "ESP32-CAM", "Antalya", "Kepez", false, [], 6 ],
  [ 2, "2S LiPo batarya 850mAh", "İki sezon kullanıldı, şişme yok. Kapasitesi iyi.", "used", 220, 1, 2, "mini-sumo", "Batarya ve Şarj", nil, "İstanbul", "Bakırköy", true, [], 2 ],
  [ 3, "3S LiPo batarya 1300mAh", "Sumo için fazla güçlü kaldı, drone için uygun.", "used", 320, 1, 1, "insansiz-hava-araci-mini-drone", "Batarya ve Şarj", nil, "İzmir", "Buca", false, %w[mini-sumo rc-sabit-kanat-ucak], 8 ],
  [ 4, "Mini sumo şasi + bıçak seti", "Lazer kesim şasi ve ön bıçak. Kullanılmış ama düzgün.", "used", 650, 1, 2, "mini-sumo", "Şasi ve Mekanik", nil, "Bursa", "İnegöl", false, [], 9 ],
  [ 5, "Çizgi izleyen şasi (3D baskı)", "3D baskı gövde, N20 motorlara uygun.", "used", 180, 1, 1, "cizgi-izleyen-temel-seviye", "Şasi ve Mekanik", nil, "Konya", "Ereğli", false, [], 11 ],
  [ 6, "40A fırçasız ESC", "Drone için 40 amper ESC. Test edildi.", "used", 520, 1, 1, "insansiz-hava-araci-mini-drone", "Motor Sürücü", nil, "Antalya", "Alanya", false, %w[rc-sabit-kanat-ucak], 4 ],
  [ 1, "Silikon tekerlek seti, sumo için", "Dört silikon tekerlek. Yüksek tutuş.", "new", 380, 1, nil, "mini-sumo", "Tekerlek", nil, "Ankara", "Sincan", false, [], 7 ],
  [ 2, "Kablo ve sarf seti", "Jumper, ısı makaronu ve konnektör karışımı.", "used", 120, 1, nil, "serbest-proje", "Kablo ve Sarf", nil, "İstanbul", "Şişli", false, [], 12 ],
  [ 3, "Leopard mini sumo kit", "Sumozade Leopard kiti. Eksiksiz, yarışmaya hazır.", "used", 2600, 1, 1, "mini-sumo", "Komple Robot / Kit", nil, "İzmir", "Gaziemir", true, [], 5 ],
  [ 4, "Raspberry Pi 5 + kamera", "Otonom araç için Pi 5 ve kamera modülü.", "new", 5400, 1, nil, "otonom-arac", "Kontrol Kartı", "RASPBERRY PI 5", "Bursa", "Gemlik", false, %w[serbest-proje], 3 ],
  [ 5, "STM32 Blue Pill", "Hızlı çizgi izleyen için hızlı MCU.", "new", 210, 2, nil, "hizli-cizgi-izleyen", "Kontrol Kartı", "STM32F103C8T6", "Konya", "Akşehir", false, [], 6 ],
  [ 6, "Teensy 4.0", "Yüksek hız projeleri için. Az kullanıldı.", "used", 700, 1, 1, "hizli-cizgi-izleyen", "Kontrol Kartı", "TEENSY 4.0", "Antalya", "Manavgat", false, [], 8 ],
  [ 1, "MPU9250 IMU, drone için", "9 eksen IMU, drone dengelemede kullandık.", "used", 180, 1, 1, "insansiz-hava-araci-mini-drone", "Sensör", "MPU9250", "Ankara", "Polatlı", false, [], 10 ],
  [ 2, "PCA9685 servo sürücü", "16 kanal PWM, robotik kol projesi için.", "new", 130, 1, nil, "endustriyel-robotik-kol", "Motor Sürücü", "PCA9685", "İstanbul", "Maltepe", false, [], 2 ],
  [ 3, "28BYJ-48 step motor + ULN2003", "Step motor ve sürücüsü birlikte.", "used", 90, 2, 1, "endustriyel-robotik-kol", "Motor", "28BYJ-48", "İzmir", "Çiğli", false, [], 9 ],
  [ 4, "LM2596 buck dönüştürücü, 5 adet", "Gerilim düşürücü modüller.", "new", 80, 5, nil, "su-ustu-robot", "Batarya ve Şarj", "LM2596", "Bursa", "Mudanya", false, [], 4 ],
  [ 5, "Su altı robot gövdesi", "Su geçirmez gövde, iticiler için hazır.", "used", 1800, 1, 1, "su-alti-robot", "Şasi ve Mekanik", nil, "Konya", "Beyşehir", false, [], 13 ],
  [ 6, "Otonom araç şasisi", "4 tekerlekli şasi, DC motorlarla uyumlu.", "used", 900, 1, 1, "otonom-arac", "Şasi ve Mekanik", nil, "Antalya", "Serik", false, [], 11 ],
  [ 1, "DHT22 sıcaklık ve nem sensörü", "Serbest proje için kullanıldı, çalışıyor.", "used", 60, 2, 1, "serbest-proje", "Sensör", "DHT22", "Ankara", "Çubuk", false, [], 14 ],
  [ 2, "nRF24L01 kablosuz modül, 2 adet", "Kumanda projesi için çift modül.", "used", 110, 2, 1, "tozkoparan-robot", "Sensör", "NRF24L01", "İstanbul", "Kartal", false, [], 7 ],
  [ 3, "RC sabit kanat gövde + kanat", "Kullanılmış gövde, köpük sağlam.", "used", 1100, 1, 1, "rc-sabit-kanat-ucak", "Şasi ve Mekanik", nil, "İzmir", "Torbalı", false, [], 15 ],
  [ 4, "Su üstü robot motor + pervane seti", "İki motor ve pervane. Test edildi.", "used", 500, 1, 1, "su-ustu-robot", "Motor", nil, "Bursa", "Orhangazi", false, [], 6 ],
  [ 5, "Siber güvenlik Raspberry Pi seti", "Pi ve temel modüller, lab için.", "used", 750, 1, 1, "siber-guvenlik", "Kontrol Kartı", nil, "Konya", "Cihanbeyli", false, [], 9 ],
  [ 6, "Komple çizgi izleyen robot", "Yarışmaya hazır çizgi izleyen, N20 + QTR-8A.", "used", 1800, 1, 1, "cizgi-izleyen-temel-seviye", "Komple Robot / Kit", nil, "Antalya", "Kemer", true, [], 5 ],
  [ 1, "Mini sumo start modülü", "Start modülü, kumandayla uyumlu.", "used", 250, 1, 2, "mini-sumo", "Kablo ve Sarf", nil, "Ankara", "Akyurt", false, [], 16 ]
].freeze

LISTINGS.each do |user_idx, title, description, condition, price, quantity, seasons_used,
                   root_slug, leaf_name, part_code, city, district, show_phone, compatible_roots, days_ago|
  listing = Listing.new(
    user: users[user_idx - 1],
    category: leaf(root_slug, leaf_name),
    part: part_code ? parts[part_code] : nil,
    title: title,
    description: description,
    condition: condition,
    price: price,
    quantity: quantity,
    seasons_used: seasons_used,
    city: city,
    district: district,
    show_phone: show_phone,
  )
  listing.published_at = days_ago.days.ago
  listing.save!

  compatible_roots.each do |root_slug_key|
    listing.compatible_categories << CATS[root_slug_key]
  end
end

# --- Bekleyen öneri örnekleri (admin paneli boş kalmasın) ---

pending1 = Part.create!(
  code: "TB6612FNG-EXT",
  name: "TB6612FNG genişletme kartı",
  brand: "SparkFun",
  category: leaf("mini-sumo", "Motor Sürücü"),
  status: "pending",
  suggested_by: users[1],
)

pending2 = Part.create!(
  code: "VL6180X",
  name: "VL6180X yakınlık ve ışık sensörü",
  brand: "STMicroelectronics",
  category: leaf("labirent-ustasi", "Sensör"),
  status: "pending",
  suggested_by: users[2],
)

Listing.create!(
  user: users[1],
  category: leaf("mini-sumo", "Motor Sürücü"),
  part: pending1,
  title: "TB6612FNG genişletme kartı, yeni nesil",
  description: "Yeni nesil sürücü kartı, onay sonrası yayına girer.",
  condition: "new",
  price: 240,
  quantity: 1,
  city: "Ankara",
  district: "Yenimahalle",
  status: "pending_part",
)

Listing.create!(
  user: users[2],
  category: leaf("labirent-ustasi", "Sensör"),
  part: pending2,
  title: "VL6180X yakınlık sensörü",
  description: "ToF yakınlık sensörü, katalog onayı bekliyor.",
  condition: "new",
  price: 210,
  quantity: 1,
  city: "İstanbul",
  district: "Kadıköy",
  status: "pending_part",
)

# --- Site sayacı ---

SiteStat.create!(key: "sold_total", value: 0)

# --- Forum bölümleri (idempotent) ---

ForumSeeder.seed_boards!
