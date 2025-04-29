# ARMeter - Arttırılmış Gerçeklik Ölçüm Uygulaması

![ARMeter Logo](ARMeter/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png)

ARMeter, iOS cihazlarında ARKit kullanarak gerçek dünyada mesafeleri ölçmenizi sağlayan bir arttırılmış gerçeklik uygulamasıdır. Kullanıcı dostu arayüzü ve çeşitli ölçüm birimleri ile hızlı ve hassas ölçümler yapabilirsiniz.

## İçindekiler

- [Özellikler](#özellikler)
- [Sistem Gereksinimleri](#sistem-gereksinimleri)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Proje Yapısı](#proje-yapısı)
- [Mimari](#mimari)
- [Kodlama Yaklaşımı](#kodlama-yaklaşımı)
- [Performans Optimizasyonları](#performans-optimizasyonları)
- [Çoklu Dil Desteği](#çoklu-dil-desteği)
- [Geliştirme Süreci](#geliştirme-süreci)
- [Gelecekteki Özellikler](#gelecekteki-özellikler)
- [Lisans](#lisans)

## Özellikler

- **Hassas Ölçüm**: ARKit ile yüzey tespiti ve gerçek dünyada hassas mesafe ölçümü
- **Çoklu Ölçüm Birimi**: Metre, santimetre, inç ve fit cinsinden ölçümler
- **Ölçüm Kaydı**: Yapılan ölçümleri kaydedebilme ve not ekleyebilme
- **Görsel Geri Bildirim**: Başlangıç ve bitiş noktaları, ölçüm çizgileri ve mesafe etiketleri
- **Haptik Geri Bildirim**: Dokunsal geri bildirimler ile daha iyi kullanıcı deneyimi
- **Çoklu Dil Desteği**: İngilizce ve Türkçe dil desteği
- **Başlangıç Rehberi**: Uygulama ilk açıldığında kullanıcıyı yönlendiren başlangıç ekranı
- **Ayarlar**: Kişiselleştirilebilir ayarlar (haptic geri bildirim, kılavuz noktaları, dil seçimi)
- **Metal Optimizasyonu**: Metal API ile geliştirilmiş performans
- **AR Yüzey Algılama**: Yatay ve dikey yüzeylerin otomatik algılanması

## Sistem Gereksinimleri

- iOS 15.0 veya üzeri
- ARKit destekleyen bir iOS cihazı (iPhone/iPad)
- Kamera erişimi
- İnternet bağlantısı gerektirmez (tamamen offline çalışır)

## Kurulum

1. Projeyi klonlayın veya indirin:
   ```bash
   git clone https://github.com/yourusername/ARMeter.git
   ```

2. Xcode'da projeyi açın:
   ```bash
   cd ARMeter
   open ARMeter.xcodeproj
   ```

3. Uygulamayı bir cihaza veya simülatöre derleyin ve çalıştırın:
   - Xcode'da uygun bir hedef cihaz seçin
   - Run butonuna tıklayın veya `Cmd+R` tuşlarına basın

> Not: ARKit işlevselliği için gerçek bir iOS cihazda test edilmesi önerilir. Simülatörde AR özellikleri tam olarak çalışmaz.

## Kullanım

### İlk Kullanım

1. Uygulamayı ilk kez açtığınızda, başlangıç rehberi ile karşılaşacaksınız.
2. Kamera izinlerini onaylayın.
3. Rehberlik adımlarını takip ederek uygulamanın temel işlevlerini öğrenin.
4. "Başla" butonuna tıklayarak ana ölçüm ekranına geçin.

### Ölçüm Yapma

1. Cihazınızı yatay veya dikey bir yüzeye doğru tutun.
2. Yüzeylerin tespit edilmesini bekleyin (ekranın üst kısmında durum mesajı göreceksiniz).
3. Ortadaki büyük ölçüm butonuna tıklayın.
4. Başlangıç noktasını seçmek için ekrana dokunun (yeşil bir nokta görünecek).
5. Bitiş noktasını seçmek için başka bir konuma dokunun (kırmızı bir nokta görünecek).
6. İki nokta arasındaki mesafe otomatik olarak hesaplanacak ve gösterilecektir.
7. Ölçümü kaydetmek için "Kaydet" butonuna tıklayın.
8. İsteğe bağlı olarak bir not ekleyebilirsiniz.

### Ölçüm Birimi Değiştirme

1. Ekranın alt kısmındaki cetvel simgesine tıklayın.
2. Açılan menüden istediğiniz ölçüm birimini seçin (m, cm, inç, fit).
3. Mevcut ve gelecekteki tüm ölçümler seçilen birimde gösterilecektir.

### Ölçüm Geçmişi

1. Ekranın alt kısmındaki saat simgesine tıklayın.
2. Kaydedilen tüm ölçümleri ve notları görüntüleyin.
3. Ölçümleri silmek için "Düzenle" butonuna tıklayın.

### Ayarlar

1. Ekranın sağ tarafındaki dişli simgesine tıklayın.
2. Haptik geri bildirimi açın/kapatın.
3. Kılavuz noktalarını açın/kapatın.
4. Dil seçimini değiştirin.
5. Uygulama hakkında bilgi alın.

## Proje Yapısı

ARMeter projesi, MVVM mimari modeli takip ederek modüler bir şekilde yapılandırılmıştır:

```
ARMeter/
├── ARMeterApp.swift          # Uygulama başlangıç noktası
├── ContentView.swift         # Ana içerik görünümü
├── Info.plist                # Uygulama yapılandırma bilgileri
├── Models/                   # Veri modelleri
│   └── MeasurementModel.swift # Ölçüm veri modeli
├── ViewModels/               # Görünüm modelleri
│   ├── AppViewModel.swift    # Uygulama durumu ve işlemleri
│   └── ARViewModel.swift     # AR işlemleri ve durumu
├── Views/                    # Kullanıcı arayüzü görünümleri
│   ├── MainView.swift        # Ana görünüm
│   ├── MeasurementView.swift # Ölçüm ekranı
│   └── OnboardingView.swift  # Başlangıç ekranı
├── Utils/                    # Yardımcı sınıflar
│   ├── HapticManager.swift   # Dokunsal geri bildirim yöneticisi
│   ├── LocalizationManager.swift # Yerelleştirme yöneticisi
│   ├── MaterialConfigurator.swift # AR malzeme yapılandırıcısı
│   └── StringExtension.swift # String uzantıları
└── Resources/                # Kaynaklar
    ├── Localization/         # Yerelleştirme dosyaları
    │   ├── en.lproj/         # İngilizce
    │   └── tr.lproj/         # Türkçe
    └── Shaders/              # Metal gölgelendiriciler
        └── ShaderConfig.metal # Metal yapılandırma
```

## Mimari

ARMeter, MVVM (Model-View-ViewModel) mimari modelini kullanarak geliştirilmiştir:

### Model Katmanı

- **MeasurementModel.swift**: Ölçüm sonuçlarını, birimlerini ve diğer ilişkili verileri tanımlayan model.
- Kullanıcı ölçümlerini ve uygulama durumunu kalıcı olarak saklama.

### View Katmanı

- **MainView.swift**: Uygulamanın ana yapısını ve gezinme akışını yöneten üst düzey görünüm.
- **MeasurementView.swift**: AR ölçüm arayüzünü, ölçüm kontrol panellerini ve kullanıcı etkileşimlerini içerir.
- **OnboardingView.swift**: İlk defa uygulama kullananlar için rehberlik ekranı.
- SwiftUI ile oluşturulmuş modüler alt görünümler (`UnitPickerView`, `SettingsView`, vb.).

### ViewModel Katmanı

- **AppViewModel.swift**: Uygulama durumunu, ölçüm işlemlerini, kullanıcı ayarlarını ve uygulama akışını yönetir.
- **ARViewModel.swift**: ARKit etkileşimleri, kamera işlemleri, yüzey algılama ve AR sahnesini yönetir.

### Yardımcı Bileşenler

- **LocalizationManager**: Çoklu dil desteği ve yerelleştirme işlemleri.
- **HapticManager**: Dokunsal geri bildirim işlemleri.
- **MaterialConfigurator**: AR nesneleri için malzeme yapılandırması.

## Kodlama Yaklaşımı

ARMeter projesinde benimsenen kodlama yaklaşımları:

### Reaktif Programlama

- **@Published** özellikleri ve Combine çerçevesi ile reaktif veri akışı.
- State değişikliklerine dayalı arayüz güncellemeleri.

### Protocol-Oriented Programming

- Protokoller ve uzantılar aracılığıyla kod yeniden kullanımı ve modülerlik.
- İşlevselliğin, belirli arayüzler üzerinden tanımlanması.

### Performans Optimizasyonu

- Metal API ile yüksek performanslı grafik işleme.
- İş parçacığı yönetimi ile UI blokajlarının önlenmesi.
- ARKit kaynaklarının verimli kullanımı.

### Memory Management

- Zayıf referanslar ve bellek sızıntılarının önlenmesi.
- Autoreleasepool ile geçici bellek kullanımının optimize edilmesi.

## Performans Optimizasyonları

ARMeter, optimize edilmiş bir kullanıcı deneyimi için çeşitli tekniklerden yararlanır:

### AR Optimizasyonları

- **Seçici Özellik Kullanımı**: Sadece gerekli ARKit özellikleri etkinleştirilmiştir.
- **Kademeli AR Başlatma**: AR oturumu, minimum yapılandırma ile başlar ve kademeli olarak geliştirilir.
- **AR Çerçeve Yönetimi**: Çerçevelerin gereksiz tutulması önlenerek bellek kullanımı optimize edilmiştir.

### Grafik Optimizasyonları

- **Basit Geometriler**: Ölçüm noktaları ve çizgiler için optimize edilmiş geometriler.
- **Metal Entegrasyonu**: Doğrudan Metal API çağrıları ile grafik işleme.
- **Basit Malzemeler**: Karmaşık malzemeler yerine basit, düşük maliyetli olanları tercih edilmiştir.

### UI Optimizasyonları

- **Asenkron İşlemler**: Arka planda gerçekleştirilen hesaplamalar ve işlemler.
- **İş Parçacığı Yönetimi**: UI blokajlarını önlemek için işlemler uygun iş parçacıklarında yürütülür.
- **Dokunmatik Olay Optimizasyonu**: Dokunma olaylarının işlenme şekli optimize edilmiştir.

## Çoklu Dil Desteği

ARMeter şu anda aşağıdaki dilleri desteklemektedir:

- İngilizce (varsayılan)
- Türkçe

Dil desteği, LocalizationManager sınıfı ve Localizable.strings dosyaları aracılığıyla sağlanmaktadır:

```swift
// Örnek kullanım
Text("place_start_point".localized)
```

Yeni dil eklemek için:

1. Resources/Localization altında yeni bir dil klasörü oluşturun (örn. `fr.lproj`).
2. Bu klasöre standart bir `Localizable.strings` dosyası ekleyin.
3. Anahtar/değer çiftlerini yeni dile çevirin.
4. LocalizationManager'a yeni dil seçeneğini ekleyin.

## Geliştirme Süreci

ARMeter projesi aşağıdaki adımları içeren bir süreçle geliştirilmiştir:

1. **Gereksinimlerin Belirlenmesi**: Kullanıcı ihtiyaçları ve uygulama özellikleri tanımlanmıştır.
2. **Mimari Tasarım**: MVVM mimarisi belirlenmiş ve proje yapısı oluşturulmuştur.
3. **AR İşlevselliği**: ARKit entegrasyonu ve temel ölçüm işlevleri geliştirilmiştir.
4. **UI Tasarımı**: Kullanıcı arayüzü ve etkileşim akışları tasarlanmıştır.
5. **Çoklu Dil Desteği**: Yerelleştirme altyapısı ve çeviriler eklenmiştir.
6. **Performans Optimizasyonu**: Uygulama performansını artırmak için optimizasyonlar yapılmıştır.
7. **Test ve Hata Düzeltmeleri**: Kapsamlı test ve hata düzeltmeleri gerçekleştirilmiştir.

## Gelecekteki Özellikler

ARMeter için planlanan gelecekteki özellikler:

- **Çoklu Ölçüm Noktaları**: Birden fazla nokta ile alan ve hacim ölçümü.
- **LiDAR Entegrasyonu**: Destekleyen cihazlarda daha hassas ölçümler için LiDAR sensörü kullanımı.
- **Ölçüm Paylaşımı**: Ölçümleri AR deneyimi veya görüntü olarak paylaşma.
- **Bölge Taraması**: Bir alanı tarayarak detaylı 3D model oluşturma.
- **Daha Fazla Dil Desteği**: Ek diller için yerelleştirme desteği.
- **Şablon Ölçümler**: Yaygın nesneler için ön tanımlı ölçüm şablonları.
- **Sesli Komutlar**: Sesli komut ile ölçüm işlemlerini yapabilme.

## Lisans

ARMeter projesi, ticari olmayan (Non-Commercial) lisans altında lisanslanmıştır. Bu lisans, yazılımın ticari olmayan amaçlarla ücretsiz olarak kullanılmasına, değiştirilmesine ve dağıtılmasına izin verirken, ticari kullanım için telif hakkı sahibinden açık yazılı izin gerektirir. Daha fazla bilgi için `LICENSE` dosyasına bakın.

