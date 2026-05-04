# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# IbisSupply — Claude Çalışma Notları

## Proje
- **Ad:** IbisSupply — Blockchain Tabanlı Gıda Tedarik Zinciri İzlenebilirlik Sistemi
- **Sahibi:** Enes İBİŞ, Karabük Üniversitesi BBSF
- **Danışman:** Doç. Dr. Funda DEMİR
- **Destek:** TÜBİTAK 2209-A
- **Deadline:** Nisan 2026 sonu
- **Repo:** https://github.com/enesibis/IbisSupply

## Stack
| Katman | Teknoloji |
|--------|-----------|
| Backend | Spring Boot 3.3, Java 21, PostgreSQL, JWT |
| Blockchain | Solidity 0.8.28, Hardhat (lokal Chain 31337) |
| Mobile | Flutter (go_router, flutter_bloc, dio) |
| AI | Python 3.14 + FastAPI + scikit-learn |

---

## Komutlar

### Backend (Spring Boot)
```bash
# Build
cd backend
mvn clean package -DskipTests

# Çalıştır — GROQ_API_KEY olmadan chatbot çalışmaz
GROQ_API_KEY=<key> java -jar target/backend-0.0.1-SNAPSHOT.jar

# Tek test çalıştır
mvn test -Dtest=AuthServiceTest

# Windows'ta JAR kilitliyse önce:
powershell Stop-Process -Name java -Force
```

### Blockchain (Hardhat)
```bash
cd blockchain
npm install

# Lokal node başlat (açık kalmalı — kapanırsa adresler sıfırlanır)
npx hardhat node

# Kontratları deploy et (node yeniden başladıysa)
npx hardhat run scripts/deploy.js --network localhost

# Tek kontrat testi
npx hardhat test test/BatchRegistry.test.js
```

### AI Servisi (FastAPI)
```bash
cd ai

# Bağımlılıkları kur
python -m pip install -r requirements.txt

# Delay modelini yeniden eğit
python delay_model.py

# Anomali modelini yeniden eğit
python anomaly_model.py

# Servisi başlat (port 8000)
python -m uvicorn main:app --port 8000 --reload
```

### Flutter (Mobile)
```bash
cd mobile
flutter pub get

# Emülatörde çalıştır
flutter run

# Release APK (66MB) — emülatör storage doluysa debug yerine bunu kullan
flutter build apk --release
# Kur:
adb install build/app/outputs/flutter-apk/app-release.apk

# Debug APK (187MB) — hot reload gerekiyorsa
flutter build apk --debug
```

---

## Çalışma Kuralları
- Backend önce yaz, sonra Flutter — API contract olmadan form field'ları kurulamaz
- NetBeans Lombok hataları (`cannot find symbol: builder()`) gerçek değil — Maven derleme çalışır
- `Map.of()` generic inference Java compiler'da bazen hata verir — `HashMap` ile yaz
- Commit mesajlarına `Co-Authored-By` satırı ekleme
- Terminal komutlarını kendin çalıştır, kullanıcıya bırakma
- Python paketlerini `python -m pip install` ile kur (`pip` komutu PATH'te yok)

---

## Mimari ve Kod Akışı

### Genel Akış
```
Flutter (Dio + BLoC)
    ↓ REST/JWT
Spring Boot Backend
    ├─→ PostgreSQL (JPA)
    ├─→ Hardhat Node :8545 (Web3j — BlockchainService)
    ├─→ FastAPI AI :8000 (RestTemplate — AiService)
    └─→ Groq API (RestTemplate — ChatService)
```

### Roller ve Erişim
`UserRole` enum: `CUSTOMER, RETAILER, LOGISTICS, WAREHOUSE, INSPECTOR, PROCESSOR, PRODUCER, ADMIN` (+ `NONE`)

- **CUSTOMER** — favoriler, şikayetler, my-products, trace (public)
- **PRODUCER** — batch oluştur/yönet, farm-records; sevkiyatları **görebilir** (oluşturamaz)
- **LOGISTICS** — shipment oluştur/yönet; kendi taşıdığı sevkiyatları görür; tüm batch'leri görür
- **WAREHOUSE** — shipment event ekle, deliver; tüm batch'leri görür
- **INSPECTOR** — quality-checks, şikayet yanıtla; tüm batch ve sevkiyatları görür
- **RETAILER / PROCESSOR** — tüm batch ve sevkiyatları görür (read-only)
- **ADMIN** — tüm yetkiler + kullanıcı yönetimi + ürün yönetimi

`BatchStatus` enum: `CREATED → IN_TRANSIT → IN_WAREHOUSE → SOLD / RECALLED`
`ProductCategory` enum: `FRUIT, VEGETABLE, GRAIN, DAIRY, LEGUME, HERB, NUT, MEAT, OIL, DEFAULT` — batch oluşturulurken kategori bu enum ile validate edilir; FISH/BAKERY gibi tarım dışı kategoriler reddedilir

### Backend Katmanları
Her özellik aynı deseni izler: `Controller → Service → Repository + BlockchainService/AiService`

- **Controller** — `@RestController`, JWT ile güvenli, DTO'lar alıp/döner
- **Service** — iş mantığı; blockchain ve AI servislere buradan çağrı yapılır
- **BlockchainService** — Web3j ile Solidity fonksiyonlarını çağırır, TX hash döner; `application.yml`'daki adresler yanlışsa sessizce skip eder
- **AiService** — `RestTemplate` ile `http://localhost:8000` çağırır; `ai.enabled=false` ise çağrı yapılmaz
- **ChatService** — `RestTemplate` ile Groq API (`https://api.groq.com/openai/v1/chat/completions`) çağırır; `GROQ_API_KEY` env var boşsa Türkçe hata mesajı döner (HTTP 200, `reply` alanında hata metni)
- **JwtAuthFilter** — her istekte `Authorization: Bearer <token>` doğrular; principal email'dir, `ROLE_` prefix yoktur (sadece `ADMIN`, `PRODUCER` vb.)
- **SecurityConfig** — expired token için `AuthenticationEntryPoint` ile **401** döner (varsayılan Spring 403'tür)
- **GlobalExceptionHandler** — `exception/GlobalExceptionHandler.java`; tüm exception'ları yakalar

### Backend API Özeti
| Prefix | Controller | Notlar |
|--------|-----------|--------|
| `/api/v1/auth` | AuthController | login, refresh, register, `PUT /password` |
| `/api/v1/batches` | BatchController | PRODUCER/ADMIN oluşturur |
| `/api/v1/shipments` | ShipmentController | LOGISTICS/ADMIN oluşturur; events, deliver, anomaly, delay, `DELETE /{id}` |
| `/api/v1/quality-checks` | QualityCheckController | kalite kaydı; PASSED → CertificateNFT mint |
| `/api/v1/farm-records` | FarmRecordController | PRODUCER; `/mine` kendi kayıtları |
| `/api/v1/products` | ProductController | `GET` liste, `GET /categories`, `GET /shelf-life/{cat}`, `POST` (ADMIN), `DELETE /{id}` (ADMIN) |
| `/api/v1/user/favorites` | FavoriteController | favoriler |
| `/api/v1/complaints` | ComplaintController | `POST`, `GET /my`, `GET` (ADMIN), `PATCH /{id}/resolve` |
| `/api/v1/alerts` | AlertController | `GET`, `GET /all`, `PATCH /{id}/resolve` |
| `/api/v1/admin/users` | AdminController | kullanıcı yönetimi, `DELETE /{id}` |
| `/api/v1/chat` | ChatController | Groq Llama 3.3 70B; model: `llama-3.3-70b-versatile` |
| `/api/v1/trace` | TraceController | `GET /batch/{batchCode}`, `GET /qr/{qrCode}` — auth gerekmez |

### Flutter Katmanları
Her özellik `features/<ad>/` altında:
- `bloc/` — `BLoC` + `Equatable`; state: `Initial → Loading → Loaded / Error`
- `model/` — `fromJson` factory ile JSON parse
- `screen/` — `BlocConsumer` veya `BlocBuilder` ile UI

**ApiClient** (`core/api/api_client.dart`): Dio interceptor'ı her istekte token ekler; 401 **ve** 403'te refresh dener. Base URL `http://10.0.2.2:8080/api/v1` — **sadece Android emülatörü**; fiziksel cihazda PC'nin yerel IP'si kullanılmalı (ör. `192.168.x.x`).

**GoRouter** (`core/utils/app_router.dart`): `/splash` başlar, `AuthBloc` state'ine göre `/login` veya `/dashboard`'a yönlendirir. `_AuthRouterNotifier` (`main.dart`) AuthBloc stream'ini `ChangeNotifier`'a köprüler — `refreshListenable` olarak geçilir.

**Locale:** `main.dart`'ta `locale: Locale('tr', 'TR')` + `flutter_localizations` — Türkçe karakter ve tarih desteği için zorunlu.

**Rol bazlı UI:** `ShipmentListScreen`'deki `+` butonu yalnızca LOGISTICS ve ADMIN'e görünür. `AuthBloc.state` cast edilip `role` alanı okunur.

**Rotalar:** `/splash`, `/login`, `/register`, `/dashboard`, `/qr-public`, `/product-trace/:batchCode`, `/batches`, `/shipments`, `/quality-checks`, `/quality-checks/create`, `/admin/users`, `/admin/users/create`, `/farm-records`, `/farm-records/create`, `/alerts`, `/profile`, `/chat`, `/my-products`, `/complaint?batchCode=`

### AI Servisi Endpoint'leri
| Endpoint | Açıklama |
|----------|----------|
| `POST /ai/analyze-anomaly` | Sıcaklık zaman serisi → anomali + risk seviyesi |
| `POST /ai/risk-score` | Batch risk skoru (anomali + kalite + son kullanma) |
| `POST /ai/predict-delay` | Gecikme tahmini (mesafe, hava, trafik, araç) |
| `GET /ai/shelf-life/{category}` | Kategori raf ömrü standardı |
| `GET /ai/demo-anomaly` | Demo endpoint |

### Blockchain Entegrasyon Notu
Hardhat her başlatmada **deterministik** adresler üretir — ilk deploy her zaman aynı adreslere gider. Node yeniden başladıysa `deploy.js` çalıştırmak yeterli; `application.yml` adresleri değişmez. `RoleManager` deploy ediliyor ama Java tarafında çağrılmıyor — `application.yml`'de tanımlı değil.

---

## Servisler (Demo Öncesi Başlatılacaklar)
```bash
# 1. Hardhat node (Terminal 1 — açık kalmalı)
cd IbisSupply/blockchain && npx hardhat node

# 2. Deploy (sadece node yeniden başladıysa)
npx hardhat run scripts/deploy.js --network localhost

# 3. AI servisi (Terminal 2)
cd IbisSupply/ai && python -m uvicorn main:app --port 8000

# 4. Backend (Terminal 3)
cd IbisSupply/backend && GROQ_API_KEY=<key> java -jar target/backend-0.0.1-SNAPSHOT.jar
```

## Test Kullanıcıları
| Email | Şifre | Rol | Organizasyon |
|-------|-------|-----|--------------|
| admin@ibissupply.com | admin123 | ADMIN | IbisSupply HQ |
| producer@ibissupply.com | producer123 | PRODUCER | Örnek Tarım A.Ş. |
| logistics@ibissupply.com | logistics123 | LOGISTICS | Hızlı Lojistik Ltd. |

Yeni `/register` endpoint'i kullanıcıyı otomatik `CUSTOMER` rolüyle oluşturur (organizasyonsuz).

## Blockchain Adresleri (deterministik — her temiz deploy'da aynı)
| Contract | Adres |
|----------|-------|
| RoleManager | 0x5FbDB2315678afecb367f032d93F642f64180aa3 |
| BatchRegistry | 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 |
| ShipmentRegistry | 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 |
| QualityRegistry | 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 |
| FarmRegistry | 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 |
| CertificateNFT | 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 |

---

## Design System (Flutter)

**Tipografi**
- `GoogleFonts.fraunces()` — büyük başlıklar (italic accent sözcük)
- `AppTheme.sans()` — tüm UI metni (Inter)
- `GoogleFonts.jetBrainsMono()` — kodlar, hash, tarihler

**Renk Token'ları** (her dosyada `const` olarak tanımlanır — `IbisColors` veya Material renkleri kullanılmaz)
```dart
const _accent     = Color(0xFF3F3FE8);
const _accentSoft = Color(0xFFEEEEFE);
const _ink900     = Color(0xFF0A0A0B);
const _ink500     = Color(0xFF71717A);
const _ink400     = Color(0xFFA1A1AA);
const _line200    = Color(0xFFE4E4E7);
const _line100    = Color(0xFFF4F4F5);
const _success    = Color(0xFF0F7A4B);
const _successSoft= Color(0xFFE6F4EE);
```
Durum renkleri: bekliyor=`_accent`, yolda/inceleme=`Color(0xFFB45309)`, teslim/geçti=`_success`, başarısız=`Color(0xFFB91C1C)`

**Liste Ekranı Şablonu**
`CustomScrollView` → `SliverAppBar(expandedHeight: 100, pinned: true)` Fraunces başlık → yatay filtre chip satırı → `SliverList` / shimmer / boş / hata sliver

**Oluşturma Ekranı Şablonu (3-Adım Wizard)**
- `_buildHeader()` — Fraunces italic başlık + "Adım X/3" chip
- `_buildStepIndicator()` — `_StepCircle` + birleşen çizgiler
- Adım içeriği — `AnimatedSwitcher` ile geçiş
- `_buildFooter()` — `BackdropFilter` blur, Geri/Devam/Kaydet butonları

**Shimmer**: `AnimationController` + `Color.lerp(_line100, Colors.white, _anim.value)` — harici shimmer kütüphanesi kullanılmaz

---

## Demo Senaryosu
**"Organik Çilek Soğuk Zincir İhlali"**
- Batch: `BTCH-202604081529-7360` (Organik Çilek, FRUIT)
- Shipment: `SHIP-202604091332-9982` — Muğla → İstanbul
- Events: DEPARTED(4.2°C) → TEMPERATURE_LOG(7.8°C⚠) → TEMPERATURE_LOG(9.5°C🔴) → DELIVERED
- AI: `isAnomaly: true`, `riskLevel: MEDIUM`, `riskScore: 34.8`
- **Not:** `ShipmentEventType` enum'da `TEMP_LOG` ve `TEMPERATURE_LOG` ikisi de tanımlı — DB verisi `TEMPERATURE_LOG` kullanıyor

---

## Yapılacaklar
- **QR Okutma testi** — `QrPublicScreen` kamera gerçek cihazda test edilmeli
- **Rapor yazımı** — TÜBİTAK 2209-A proje raporu

## Ürün Yönetimi Notu
- Sistemde yalnızca tarımsal ürünler olmalı — `ProductCategory` enum dışındaki kategoriler backend'de reddedilir
- DB'deki ürünler şu an sadece FRUIT ve VEGETABLE; yeni kategori eklenecekse ADMIN ile `POST /api/v1/products` kullanılır
- `DataInitializer` yalnızca `productRepository.count() == 0` ise seed çalıştırır — elle eklenen ürünler korunur
