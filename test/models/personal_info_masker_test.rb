require "test_helper"

class PersonalInfoMaskerTest < ActiveSupport::TestCase
  def masked?(text)
    _masked, changed = PersonalInfoMasker.call(text)
    changed
  end

  test "Türkiye cep telefonu varyantları maskelenir" do
    [
      "0555 000 00 01",
      "05550000001",
      "0 555 000 00 01",
      "+90 555 000 00 01",
      "+905550000001",
      "90555 000 00 01",
      "0555.000.00.01",
      "0555-000-00-01"
    ].each do |phone|
      assert masked?("Bana #{phone} numaradan ulaş."), "#{phone} maskelenmeliydi"
    end
  end

  test "e-posta maskelenir" do
    assert masked?("efe.kaya@example.com adresine yaz")
    masked, = PersonalInfoMasker.call("Mail: test+etiket@robotakas.test")
    assert_equal "Mail: •••", masked
  end

  test "maskelenen metin geri alınamaz ve işaretlenir" do
    masked, changed = PersonalInfoMasker.call("Ara: 0555 000 00 01")
    assert changed
    assert_equal "Ara: •••", masked
  end

  test "parça kodları etkilenmez" do
    [
      "TB6612FNG çift motor sürücü",
      "ESP32-CAM kamera",
      "STM32F103C8T6 Blue Pill",
      "VL53L0X ve QTR-8A sensör",
      "LM2596 buck dönüştürücü",
      "PCA9685 sürücü"
    ].each do |text|
      refute masked?(text), "#{text} yanlış maskelendi"
    end
  end

  test "fiyat ve değerler etkilenmez" do
    [
      "Fiyat 1.250 TL",
      "5.000 TL istiyorum",
      "5V 2A adaptör",
      "3000mAh batarya",
      "12.10.2026 tarihinde",
      "5000 rpm motor",
      "8 MB dosya"
    ].each do |text|
      refute masked?(text), "#{text} yanlış maskelendi"
    end
  end

  test "kısa sayı dizileri etkilenmez" do
    refute masked?("12345")
    refute masked?("555")
    refute masked?("3 adet motor")
  end

  test "uzun başka sayı telefon değildir" do
    refute masked?("1234567890")
    refute masked?("9999999999")
  end
end
