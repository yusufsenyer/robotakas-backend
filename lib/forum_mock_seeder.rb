module ForumMockSeeder
  ADMIN_EMAIL = "admin@robotakas.test".freeze
  PASSWORD = "Demo1234!".freeze
  ANSWER_OFFSETS = [ 25, 180, 600, 1500 ].freeze

  USERS = [
    { key: :emre, full_name: "Emre Kaya", email: "emre.kaya@robotakas.test", city: "İzmir", team_name: "Ege Robotik" },
    { key: :burak, full_name: "Burak Demir", email: "burak.demir@robotakas.test", city: "İstanbul", team_name: "Boğaz Mekatronik" },
    { key: :mert, full_name: "Mert Yıldız", email: "mert.yildiz@robotakas.test", city: "Eskişehir", team_name: "Anadolu Çizgi" },
    { key: :deniz, full_name: "Deniz Arslan", email: "deniz.arslan@robotakas.test", city: "Antalya", team_name: "Akdeniz Drone" },
    { key: :zeynep, full_name: "Zeynep Aydın", email: "zeynep.aydin@robotakas.test", city: "Ankara", team_name: "Başkent Bot" },
    { key: :elif, full_name: "Elif Şahin", email: "elif.sahin@robotakas.test", city: "Bursa", team_name: "Uludağ Robot" },
    { key: :kerem, full_name: "Kerem Koç", email: "kerem.koc@robotakas.test", city: "Kocaeli", team_name: "Körfez Otonom" },
    { key: :selin, full_name: "Selin Güneş", email: "selin.gunes@robotakas.test", city: "Samsun", team_name: "Karadeniz Maker" },
    { key: :can, full_name: "Can Öztürk", email: "can.ozturk@robotakas.test", city: "İzmir", team_name: "Gediz Robotik" },
    { key: :ayse, full_name: "Ayşe Çelik", email: "ayse.celik@robotakas.test", city: "Konya", team_name: "Selçuk Bot" }
  ].freeze

  TOPICS = [
    {
      board: "mini-sumo", author: :can, kind: "question",
      title: "Mini sumo için motor seçimi",
      days_ago: 11, views: 112, solved_index: 0,
      body: <<~MD,
        İlk mini sumo robotumu topluyorum, birkaç konuda kararsız kaldım.

        Elimde **2S LiPo (7,4 V)** var. N20 mi yoksa daha büyük bir motor mu kullanmalıyım? 6 V mu 12 V mu seçsem bilemedim. Robotun ağırlık sınırını da düşünüyorum; ilgili yarışmanın güncel şartnamesine bakacağım.

        Sürücü olarak TB6612FNG düşünüyorum, sizce ilk robot için uygun mu?
      MD
      answers: [
        { author: :emre, likes: 4, body: <<~MD },
          Mini sumo'da belirleyici olan hız değil, **tork ve çekiş**. Başlangıç için 6 V N20 (yaklaşık 300-600 RPM dişli oranı) 2S ile TB6612FNG üzerinden sürülebilir; PWM'i yaklaşık %80-85 ile sınırla.

          TB6612FNG kanal başına sürekli yaklaşık 1,2 A verir. İki robot itişirken motor akımı artar, ısınmayı izle.

          Yumuşak kauçuk ya da silikon tekerlek tutuşu artırır.
        MD
        { author: :burak, body: <<~MD },
          12 V motor için 3S gerekir; hem ağırlık hem hacim büyür, ilk robot için gerek yok. Ön kamayı zemine yakın tut.
        MD
        { author: :can, body: <<~MD },
          Peki 1000 RPM'li modeli alsam olur mu?
        MD
        { author: :mert, body: <<~MD }
          1000 RPM'de tork düşük kalır; ilk robot için yaklaşık 500 civarı daha güvenli.
        MD
      ]
    },
    {
      board: "mini-sumo", author: :zeynep, kind: "question",
      title: "Rakip algılamada VL53L0X mi IR sensör mü?",
      days_ago: 1, views: 34,
      body: <<~MD,
        Rakip algılama için **VL53L0X** (I2C, ToF) ile klasik analog IR mesafe sensörü arasında kaldım.

        Ortam ışığı, siyah yüzey tepkisi ve iki VL53L0X kullanınca I2C adres çakışması (XSHUT ile adres atama) konusunda tecrübeniz nedir? Maliyet de önemli.
      MD
      answers: []
    },
    {
      board: "mini-sumo", author: :elif, kind: "showcase",
      title: "3D baskı şasimiz için geri bildirim",
      days_ago: 9, views: 67, topic_likes: 3,
      body: <<~MD,
        10×10 cm tabanlı şasiyi **PETG** ile bastım. Ön kama var, duvar kalınlığı yaklaşık 3 mm, dolgu %40, motorlar arkada; hedef ağırlık yaklaşık 450 g.

        Ağırlık dağılımı ve kama açısı için görüşünüzü almak istiyorum. Görsel ekleyemedim, metinle anlatıyorum.
      MD
      answers: [
        { author: :burak, body: <<~MD },
          PETG, PLA'dan daha dayanıklı. Kama ucu zemine çok yakın olsun, yaklaşık 1 mm; ağırlığı alta ve öne ver.
        MD
        { author: :mert, body: <<~MD }
          Kama ucuna ince çelik şerit eklemeyi dene. Ölçü ve ağırlık için ilgili yarışmanın güncel şartnamesine bak.
        MD
      ]
    },
    {
      board: "cizgi-izleyen-temel-seviye", author: :ayse, kind: "question",
      title: "Çizgi izleyen robotta sensör ayarı",
      days_ago: 8, views: 89, solved_index: 0,
      body: <<~MD,
        QTR tipi analog sensör dizisi kullanıyorum. Siyah-beyaz ayrımı güvenilmez; değerler dalgalanıyor (beyazda yaklaşık 200-400, siyahta 700-900 ama bazen karışıyor).

        Eşik değerini nasıl bulmalıyım?
      MD
      answers: [
        { author: :mert, likes: 3, body: <<~MD },
          Kalibrasyon yap: robotu çizgi üzerinde sağa-sola gezdirip her sensör için **min/max** kaydet; eşik = (min+max)/2. İstersen değerleri 0-1000 aralığına normalize et.

          Sensör-zemin mesafesi yaklaşık 3-8 mm olsun, yan ışığı engelle.
        MD
        { author: :emre, body: <<~MD },
          Yüksekliği sabitle ve birkaç okumanın ortalamasını al.
        MD
        { author: :ayse, body: <<~MD }
          Yüksekliği 5 mm yaptım, kalibrasyondan sonra düzeldi. Teşekkürler!
        MD
      ]
    },
    {
      board: "cizgi-izleyen-temel-seviye", author: :elif, kind: "discussion",
      title: "QTR-8A ile PID başlangıç değerleri",
      days_ago: 6, views: 138,
      body: <<~MD,
        8 sensörlü dizi kullanıyorum; konum 0-7000 (merkez 3500), hata = konum - 3500, PWM 0-255 ve taban hız yaklaşık 120.

        Kp ve Kd için başlangıç değerleri ne olmalı?

        ```cpp
        float hata = konum - 3500;
        ```
      MD
      answers: [
        { author: :mert, likes: 3, body: <<~MD },
          Ki=0, Kd=0 ile başla. Kp'yi robot salınmaya başlayana kadar artır, sonra yaklaşık yarıya indir, ardından Kd ekle.

          Başlangıç için Kp yaklaşık 0,03-0,1 arası denenebilir (hata ölçeğine ve hıza bağlı).
        MD
        { author: :emre, body: <<~MD },
          Döngü süresi sabit ve kısa (birkaç ms) olmalı. Yoksa Kd anlamsızlaşır.
        MD
        { author: :burak, reply_to: 0, body: <<~MD },
          Ki ile uğraşma; çoğu çizgi izleyende gerekmez.
        MD
        { author: :elif, body: <<~MD }
          Kendi robotumda Kp 0,05 ve Kd 0,6 civarı iyi gitti. Yine de sizin robotunuzda deneyip görmek en doğrusu. Teşekkürler.
        MD
      ]
    },
    {
      board: "cizgi-izleyen-temel-seviye", author: :can, kind: "question",
      title: "Eşik değeri sınıf ışığında kayıyor",
      hours_ago: 6, views: 21,
      body: <<~MD,
        Evde ayarladığım eşik okulda floresan ışıkta tutmuyor; değerler yaklaşık 100-150 birim kayıyor.

        Yarışma salonunda da böyle olur mu diye endişeleniyorum, ne yapmalıyım?
      MD
      answers: []
    },
    {
      board: "hizli-cizgi-izleyen", author: :burak, kind: "discussion",
      title: "Hızlı çizgi için motor ve dişli oranı",
      days_ago: 4, views: 76,
      body: <<~MD,
        N20 1000 RPM mi 600 RPM mi? 25 mm tekerle 1000 RPM yaklaşık 1,3 m/s (yaklaşık 78 m/dk), 600 RPM yaklaşık 0,8 m/s.

        Yüksek hızda sensör döngüsü ve çekiş sınırlarını konuşmak istiyorum.
      MD
      answers: [
        { author: :emre, likes: 2, body: <<~MD },
          1,3 m/s'de 5 ms'lik döngüde robot yaklaşık 6,5 mm ilerler; yani döngü hızı hız limitini belirler.
        MD
        { author: :mert, body: <<~MD },
          Önce çekiş; hız lastik ve zemine bağlı.
        MD
        { author: :zeynep, body: <<~MD },
          Kendi robotumda 600'e düşürünce tur süresi daha stabil oldu.
        MD
        { author: :burak, reply_to: 0, body: <<~MD }
          800 civarını deneyeceğim, teşekkürler.
        MD
      ]
    },
    {
      board: "hizli-cizgi-izleyen", author: :zeynep, kind: "question",
      title: "Ön sensör dizisi mesafesi nasıl seçilir?",
      days_ago: 12, views: 104, solved_index: 0,
      body: <<~MD,
        Sensör dizisi tekerlek eksenine ne kadar önde olmalı? Şu an yaklaşık 4 cm; virajlarda geç tepki veriyor.

        Daha ileri alırsam denge bozulur mu?
      MD
      answers: [
        { author: :emre, likes: 2, body: <<~MD },
          Yaklaşık 5-8 cm önde başla, hıza göre dene. Uzaklaştıkça erken algı artar ama salınım da artar.

          Kademeli test et ve çizgi kalınlığı için ilgili yarışmanın güncel şartnamesine bak.
        MD
        { author: :mert, body: <<~MD },
          Ağırlık merkezini de kontrol et.
        MD
        { author: :zeynep, body: <<~MD }
          7 cm yaptım, daha iyi oldu. Teşekkürler.
        MD
      ]
    },
    {
      board: "labirent-ustasi", author: :mert, kind: "discussion",
      title: "Sol duvar takibi mi flood fill mi?",
      days_ago: 5, views: 58,
      body: <<~MD,
        Sol duvar takibi basit ama hedef labirentin içindeyse ve döngü varsa takılabilir.

        Flood fill (BFS) mesafe haritası çıkarır; 16×16 = 256 hücre Arduino'ya sığar. İlk koşu keşif, ikinci koşu hızlı koşu olabilir. Sizce hangisi?
      MD
      answers: [
        { author: :emre, body: <<~MD },
          İlk robotta sol duvarla başla; sensör ve motor sorunlarını çöz, sonra algoritmaya geç.
        MD
        { author: :kerem, body: <<~MD },
          Flood fill'de duvar haritasını bitmask ile sakla, hafif olur.
        MD
        { author: :ayse, body: <<~MD }
          Yarışma labirentinde döngü olup olmadığını nereden öğrenebilirim?
        MD
      ]
    },
    {
      board: "otonom-arac", author: :kerem, kind: "question",
      title: "Şerit takibi için kamera mı sensör mü?",
      hours_ago: 3, views: 26,
      body: <<~MD,
        Raspberry Pi + kamera + OpenCV ile mi, yoksa 5'li IR dizisiyle mi gideyim?

        Gecikme, ışık değişimi, güç tüketimi ve pist şeritleri konusunda görüşünüzü almak istiyorum.
      MD
      answers: []
    },
    {
      board: "insansiz-hava-araci-mini-drone", author: :selin, kind: "seeking",
      title: "5 inç mini drone için parça listesi",
      days_ago: 2, views: 41,
      body: <<~MD,
        İlk 5 inç drone'umu topluyorum, **4S** düşünüyorum ve bütçem sınırlı.

        Motor, ESC, uçuş kontrolcüsü ve batarya için bir başlangıç listesi paylaşır mısınız?
      MD
      answers: [
        { author: :deniz, body: <<~MD },
          Tipik 5 inç yapı: 4S ile 2306 motor (yaklaşık 1700-2000 KV), 5045 pervane, 30×30 mm uçuş kontrolcüsü + 4'ü 1 arada ESC (yaklaşık 35-45 A), 4S 1300-1500 mAh batarya.

          Motor-pervane-batarya uyumunu birlikte seç.
        MD
        { author: :kerem, body: <<~MD }
          Yedek pervane al ve simülatörde başla.
        MD
      ]
    },
    {
      board: "yeni-baslayanlar", author: :selin, kind: "question",
      title: "Yarışma kuralları ve hazırlık süreci",
      days_ago: 10, views: 149, solved_index: 0,
      body: <<~MD,
        İlk kez bir robot yarışmasına katılacağım ama nereden başlayacağımı bilmiyorum.

        Kategori seçimi, şartname, başvuru ve hazırlık adımları konusunda yol gösterir misiniz?
      MD
      answers: [
        { author: :emre, likes: 4, body: <<~MD },
          Kontrol listesi:

          1. İlgili yarışmanın güncel şartnamesini oku; boyut, ağırlık ve motor/pil sınırları kategoriye göre değişir.
          2. Kategori seç: yeni başlayan için mini sumo ya da temel çizgi izleyen mantıklı.
          3. Başvuru ve takvimi takip et.
          4. Parça ve yedek parça listesi hazırla.
          5. Ring/pist yapıp test et.
          6. Yarışma günü teknik kontrole (ağırlık/ölçü) hazır ol.
        MD
        { author: :zeynep, body: <<~MD },
          Pist testi ve yedek batarya çok işe yarıyor.
        MD
        { author: :selin, body: <<~MD }
          Teşekkürler, ilk adım şartnameyi okumak olacak.
        MD
      ]
    },
    {
      board: "yeni-baslayanlar", author: :admin, kind: "discussion",
      title: "İlk robotum için rehber: nereden başlamalı?",
      days_ago: 14, views: 150, pinned: true, topic_likes: 5,
      body: <<~MD,
        ## Kısa rehber

        1. Kategori seç.
        2. Temel parçalar: Arduino Nano, TB6612FNG, N20 motorlar, 2S LiPo, tekerlek.
        3. Montaj.
        4. İlk test: motoru ileri süren küçük bir kod.
        5. Sorularını forumda sor.

        ```cpp
        // basit ileri hareket
        const int sag = 10;
        void setup() { pinMode(sag, OUTPUT); }
        void loop() { analogWrite(sag, 120); }
        ```
      MD
      answers: [
        { author: :can, body: <<~MD },
          Teşekkürler, listeyi kaydettim. Motor sürücüsünü nereden seçmeliyim?
        MD
        { author: :ayse, body: <<~MD }
          Bu rehber çok işime yaradı, sağ olun.
        MD
      ]
    },
    {
      board: "duyurular-ve-oneriler", author: :admin, kind: "discussion",
      title: "Forum kuralları ve duyurular",
      days_ago: 13, views: 120, pinned: true,
      body: <<~MD,
        Kısa kural özeti:

        - Saygılı ol.
        - Konuyu doğru bölüme aç.
        - Kişisel bilgi paylaşma.
        - Spam yok.

        Tam metin: [Forum kuralları](/forum/kurallar).
      MD
      answers: [
        { author: :selin, body: <<~MD }
          Anlaşıldı, teşekkürler.
        MD
      ]
    },
    {
      board: "genel-sohbet", author: :ayse, kind: "discussion",
      title: "Takım arıyorum (süresi doldu)",
      days_ago: 7, views: 47, locked: true,
      body: <<~MD,
        Konya'da mini sumo için 2-3 kişilik bir takım arıyorum.

        İlgilenenler özel mesaj atsın lütfen; buraya telefon ya da e-posta yazmayın.
      MD
      answers: [
        { author: :kerem, body: <<~MD },
          İlgileniyorum, biraz daha bilgi verir misin?
        MD
        { author: :ayse, body: <<~MD }
          Takım tamamlandı, ilgilenen herkese teşekkürler.
        MD
      ]
    }
  ].freeze

  def self.seed!
    summary = {
      boards_created: 0,
      users_created: 0,
      topics_created: [],
      topics_skipped: [],
      posts_created: 0,
      likes_created: 0,
      solved: 0,
      notifications_marked_read: 0
    }

    summary[:boards_created] = ForumSeeder.seed_boards! if ForumBoard.none?

    admin = User.find_by(email: ADMIN_EMAIL)
    raise "Admin bulunamadı (#{ADMIN_EMAIL}). Önce bin/rails db:seed çalıştır." if admin.nil?

    users = {}
    USERS.each do |attrs|
      record = User.find_or_create_by!(email: attrs[:email]) do |user|
        user.full_name = attrs[:full_name]
        user.city = attrs[:city]
        user.team_name = attrs[:team_name]
        user.password = PASSWORD
        user.role = "user"
      end
      summary[:users_created] += 1 if record.previously_new_record?
      users[attrs[:key]] = record
    end
    users[:admin] = admin

    notification_floor = Notification.maximum(:id).to_i

    TOPICS.each do |spec|
      author = users.fetch(spec[:author])

      if ForumTopic.exists?(user: author, title: spec[:title])
        summary[:topics_skipped] << spec[:title]
        next
      end

      base = if spec[:hours_ago]
        Time.current - spec[:hours_ago].hours
      else
        Time.current - spec[:days_ago].days
      end

      topic = ForumTopic.create!(
        forum_board: ForumBoard.find_by!(slug: spec[:board]),
        user: author,
        kind: spec[:kind],
        title: spec[:title],
        body: spec[:body],
        created_at: base,
        updated_at: base,
      )

      posts = []
      spec.fetch(:answers, []).each_with_index do |answer, index|
        answer_author = users.fetch(answer[:author])
        at = base + ANSWER_OFFSETS[index].minutes
        post = topic.forum_posts.create!(
          user: answer_author,
          body: answer[:body],
          created_at: at,
          updated_at: at,
        )
        post.update_column(:reply_to_post_id, posts[answer[:reply_to]].id) if answer[:reply_to]
        posts << post
        summary[:posts_created] += 1
        summary[:likes_created] += like_post(post, answer_author.id, answer[:likes].to_i, users)
      end

      summary[:likes_created] += like_topic(topic, spec[:topic_likes].to_i, users)

      if spec[:solved_index]
        solution = posts[spec[:solved_index]]
        topic.solve!(solution, actor: topic.user)
        topic.update_column(:solved_at, solution.created_at + 2.hours)
        summary[:solved] += 1
      end

      topic.update_column(:views_count, spec[:views].to_i) if spec[:views]
      topic.update_column(:pinned, true) if spec[:pinned]
      topic.update_column(:locked, true) if spec[:locked]

      summary[:topics_created] << spec[:title]
    end

    ForumTopic.find_each(&:recalculate_counters!)
    ForumBoard.find_each(&:recalculate_counters!)

    new_notifications = Notification.where("id > ?", notification_floor).where(read_at: nil)
    summary[:notifications_marked_read] = new_notifications.count
    new_notifications.update_all(read_at: Time.current, updated_at: Time.current)

    summary
  end

  def self.like_post(post, author_id, count, users)
    return 0 if count <= 0

    created = 0
    candidates(users, author_id).first(count).each do |liker|
      ForumLike.create!(user: liker, forum_post: post)
      created += 1
    end
    created
  end

  def self.like_topic(topic, count, users)
    return 0 if count <= 0

    created = 0
    candidates(users, topic.user_id).first(count).each do |liker|
      ForumLike.create!(user: liker, forum_topic: topic)
      created += 1
    end
    created
  end

  def self.candidates(users, excluded_user_id)
    USERS.map { |attrs| users.fetch(attrs[:key]) }.reject { |user| user.id == excluded_user_id }
  end
end
