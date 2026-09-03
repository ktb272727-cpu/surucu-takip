# Sürücü Takip – Flutter ilk sürüm

Konuştuğumuz temel ilk sürüm özellikleri:
- Dairesel kullanıcı logosu ve "Sürücü Takip" adı.
- Ana ekranda toplam yolculuk sayısı.
- Toplam kazanç, Nakit, POS, IBAN ve Borç özetleri.
- + Yeni Yolculuk Ekle.
- Tutar alanında sayısal klavye.
- Nakit / POS / IBAN / Borç ödeme türleri.
- Borç seçilince borçlu adı ve not.
- Kaydetmeden önce "Kaydı onaylıyor musunuz?" penceresi.
- Onay sonrası yaklaşık 1 saniyelik başarı bildirimi.
- Yolculukları düzenleme ve silme.
- Borçlar ekranında borçlu adı, tutar, tarih-saat ve Ödendi butonu.
- Ödendi yapılan borç listeden kaldırılır.
- Toplam aktif borç, borçlu sayısı ve toplam borç tutarı.
- Veriler SharedPreferences ile cihazda kalıcı tutulur.
- Sağ üst üç çizgi menüsünde sürücü adı, yolculuklar, borçlar ve hakkında.

## Çalıştırma
Flutter kurulu bir bilgisayarda:
1. `flutter pub get`
2. Android telefon/emülatör bağla.
3. `flutter run`

APK:
`flutter build apk --release`

Not: Bu sohbet ortamında Flutter SDK bulunmadığı için APK burada derlenmiş değil; proje kaynakları APK üretmeye hazırdır.
