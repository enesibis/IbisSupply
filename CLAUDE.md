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

# Çalıştır
java -jar target/backend-0.0.1-SNAPSHOT.jar

# Tek test çalıştır
mvn test -Dtest=AuthServiceTest

# Tüm testler
mvn test

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
    └─→ FastAPI AI :8000 (RestTemplate — AiService)
```

### Backend Katmanları
Her özellik aynı deseni izler: `Controller → Service → Repository + BlockchainService/AiService`

- **Controller** — `@RestController`, JWT ile güvenli, DTO'lar alıp/döner
- **Service** — iş mantığı; blockchain ve AI servislere buradan çağrı yapılır
- **BlockchainService** — Web3j ile Solidity fonksiyonlarını çağırır, TX hash döner; `application.yml`'daki adresler yanlışsa sessizce skip eder
- **AiService** — `RestTemplate` ile `http://localhost:8000` çağırır; `ai.enabled=false` ise çağrı yapılmaz
- **JwtAuthFilter** — her istekte `Authorization: Bearer <token>` doğrular; principal email'dir, `ROLE_` prefix yoktur (sadece `ADMIN`, `PRODUCER` vb.)
- **SecurityConfig** — expired token için `AuthenticationEntryPoint` ile **401** döner (varsayılan Spring 403'tür)

### Flutter Katmanları
Her özellik `features/<ad>/` altında:
- `bloc/` — `BLoC` + `Equatable`; state: `Initial → Loading → Loaded / Error`
- `model/` — `fromJson` factory ile JSON parse
- `screen/` — `BlocConsumer` veya `BlocBuilder` ile UI

**ApiClient** (`core/api/api_client.dart`): Dio interceptor'ı her istekte token ekler; 401 **ve** 403'te refresh dener (Spring expired token için 403 döndürebilir).

**GoRouter** (`core/utils/app_router.dart`): `/splash` başlar, `AuthBloc` state'ine göre `/login` veya `/dashboard`'a yönlendirir.

### AI Servisi Endpoint'leri
| Endpoint | Açıklama |
|----------|----------|
| `POST /ai/analyze-anomaly` | Sıcaklık zaman serisi → anomali + risk seviyesi |
| `POST /ai/risk-score` | Batch risk skoru (anomali + kalite + son kullanma) |
| `POST /ai/predict-delay` | Gecikme tahmini (mesafe, hava, trafik, araç) |
| `GET /ai/shelf-life/{category}` | Kategori raf ömrü standardı |
| `GET /ai/demo-anomaly` | Demo endpoint |

### Blockchain Entegrasyon Notu
Hardhat her başlatmada **deterministik** adresler üretir — ilk deploy her zaman aynı adreslere gider. Node yeniden başladıysa `deploy.js` çalıştır, `application.yml` adreslerini güncelle.

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
cd IbisSupply/backend && java -jar target/backend-0.0.1-SNAPSHOT.jar
```

## Test Kullanıcıları
| Email | Şifre | Rol |
|-------|-------|-----|
| admin@ibissupply.com | admin123 | ADMIN |
| producer@ibissupply.com | producer123 | PRODUCER |

## Blockchain Adresleri (son deploy — node yeniden başlarsa değişir)
| Contract | Adres |
|----------|-------|
| RoleManager | 0x0B306BF915C4d645ff596e518fAf3F9669b97016 |
| BatchRegistry | 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1 |
| ShipmentRegistry | 0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE |
| QualityRegistry | 0x68B1D87F95878fE05B998F19b66F4baba5De1aed |
| FarmRegistry | 0x3Aa5ebB10DC797CAC828524e59A333d0A371443c |
| CertificateNFT | 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d |

---

## Tamamlanan Modüller

### Backend
- JWT Auth (login, refresh, register) — `AuthController`
- `JwtAuthFilter`: email principal, `ROLE_` prefix yok (sadece `ADMIN`, `PRODUCER` vs.)
- `SecurityConfig`: `AuthenticationEntryPoint` ile expired token için 401 döndürür (403 değil)
- `ProductController` — `GET /api/v1/products`, `GET /api/v1/products/shelf-life/{category}`
- `BatchController` — `POST/GET /api/v1/batches`, status update
- `ShipmentController` — `POST/GET /api/v1/shipments`, events, deliver, `GET /{id}/anomaly`
- `QualityCheckController` — kalite kontrol kaydı
- `AdminController` — kullanıcı yönetimi
- `FavoriteController` — `GET/POST /api/v1/user/favorites`, `DELETE /api/v1/user/favorites/{batchCode}`
- `ComplaintController` — `POST /api/v1/complaints`, `GET /complaints/my`, `GET /complaints` (ADMIN)
- `FarmRecordController` — `POST/GET /api/v1/farm-records`, `GET /farm-records/mine` (PRODUCER)
- `AlertController` — `GET /api/v1/alerts`, `GET /alerts/all`, `PATCH /alerts/{id}/resolve`
- `DataInitializer`: admin + producer user + 20 ürün seed (8 kategoride)
- `BlockchainService`: Web3j bridge — batch/shipment/quality/farm kayıtlarını Hardhat'a yazar, TX hash döner
- `AiService`: Python FastAPI'ye RestTemplate ile bağlanır — anomali analizi + risk skoru + raf ömrü
- `AlertService`: anomali ve kalite başarısızlıklarında otomatik uyarı oluşturur
- **BUG FIX**: `durationHours` hesabında `Math.max(1.0, ...)` — sıfır gönderilince AI 422 hatasını önler

### Blockchain (Solidity)
- `RoleManager.sol`, `BatchRegistry.sol`, `ShipmentRegistry.sol`, `QualityRegistry.sol`, `FarmRegistry.sol`, `CertificateNFT.sol`
- Deploy script: `blockchain/scripts/deploy.js`, adresleri `deployed-addresses.json`'a kaydeder

### AI (Python FastAPI — port 8000)
- `anomaly_model.py`: RandomForest + rule-based hybrid, 600 sentetik veri, `model.pkl`
- `delay_model.py`: RandomForest (sınıflandırma + regresyon), 800 sentetik veri, `delay_model.pkl`
- `main.py`: 7 endpoint — anomali, risk skoru, gecikme tahmini, raf ömrü, demo
- 8 ürün kategorisi: MEAT/FISH/DAIRY/FROZEN/VEGETABLE/FRUIT/BAKERY/DRY_GOODS

### Flutter
- Login, Register, Splash, Dashboard (rol bazlı menü)
- Batch: list, create (raf ömrü otomatik), detail (QR + TX hash + NFT sertifika kartı)
- Shipment: list, create, detail (event timeline + AI anomali banner)
- Kalite kontrol, Admin, Customer (favoriler, şikayet), Farm Record, Alerts, Profile
- GoRouter rotaları: `/splash`, `/login`, `/register`, `/dashboard`, `/qr-public`, `/batches`, `/shipments`, `/quality-checks`, `/admin/users`, `/product-trace/:batchCode`, `/my-products`, `/complaint`, `/farm-records`, `/farm-records/create`, `/alerts`, `/profile`
- `ApiClient`: 401 ve 403'te token refresh dener
- Emülatör için `http://10.0.2.2:8080/api/v1`

---

## Demo Senaryosu (Hazır — 2026-04-09)
**"Organik Çilek Soğuk Zincir İhlali"**
- Batch: `BTCH-202604081529-7360` (Organik Çilek, FRUIT)
- Shipment: `SHIP-202604091332-9982` — Muğla → İstanbul
- Events: DEPARTED(4.2°C) → TEMP_LOG(7.8°C⚠) → TEMP_LOG(9.5°C🔴) → DELIVERED
- AI: `isAnomaly: true`, `riskLevel: MEDIUM`, `riskScore: 34.8`

---

## Yapılacaklar

### Tamamlandı
- Gecikme tahmini — backend `GET /{id}/delay` + Flutter `ShipmentDetailScreen`
- Şifre değiştir — `PUT /auth/password` + Flutter dialog
- Chatbot — Groq Llama 3.3 70B, backend + Flutter chat ekranı
- Sertifika NFT — `CertificateNFT.sol` ERC-721, kalite PASSED → otomatik mint, `BatchDetailScreen`'de altın kart

---

## Review Bulguları (2026-04-17)

Proje genelinde kod review sonucu tespit edilen eksikler, önem sırasına göre:

### Tamamlandı (2026-04-17)

- [x] **Global Exception Handler** — `exception/GlobalExceptionHandler.java` oluşturuldu
- [x] **`@Valid` annotasyonu** — `BatchController`, `FarmRecordController`, `QualityCheckController` + DTO validation
- [x] **Blockchain private key** — `${BLOCKCHAIN_PRIVATE_KEY:...}` env variable formatına çevrildi
- [x] **Şikayet yanıtlama** — `PATCH /complaints/{id}/resolve` (ADMIN/INSPECTOR) eklendi
- [x] **`ComplaintResponse` + `FavoriteResponse` DTO'ları** — type-safe DTO'lar, Map kaldırıldı
- [x] **Favoriye ekleme UI** — `FavoriteAdded` state listener eklendi, liste yenileniyor
- [x] **PRODUCER sevkiyat yetkisi** — `ShipmentController.create`'den PRODUCER kaldırıldı
- [x] **Null Pointer** — `FarmRecordResponse.from()` null check eklendi
- [x] **`ShipmentEventType` enum** — `String eventType` → enum; `ShipmentService` güncellendi
- [x] **`updatedAt` alanları** — `Shipment` + `ProductBatch` entity'lerine `@UpdateTimestamp` eklendi
- [x] **Admin kullanıcı silme** — `DELETE /admin/users/{id}` eklendi

### Ertelendi
- **QR Okutma testi** — `QrPublicScreen` kamera gerçek cihazda test edilmeli
- **Rapor yazımı** — TÜBİTAK 2209-A proje raporu
