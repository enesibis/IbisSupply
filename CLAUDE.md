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

## Çalışma Kuralları
- Backend önce yaz, sonra Flutter — API contract olmadan form field'ları kurulamaz
- `mvn clean package -DskipTests` ile build, `java -jar target/backend-0.0.1-SNAPSHOT.jar` ile başlat
- NetBeans Lombok hataları (`cannot find symbol: builder()`) gerçek değil — Maven derleme çalışır
- `Map.of()` generic inference Java compiler'da bazen hata verir — `HashMap` ile yaz
- Commit mesajlarına `Co-Authored-By` satırı ekleme
- Terminal komutlarını kendin çalıştır, kullanıcıya bırakma
- Python paketlerini `python -m pip install` ile kur (`pip` komutu PATH'te yok)
- Windows'ta JAR kilitliyse: `powershell Stop-Process -Name java -Force` sonra Maven

## Servisler (Demo Öncesi Başlatılacaklar)
```bash
# 1. Hardhat node (ayrı terminal — kapanırsa contract adresleri geçersiz olur)
cd IbisSupply/blockchain
npx hardhat node

# 2. Deploy (sadece node yeniden başladıysa)
npx hardhat run scripts/deploy.js --network localhost
# Çıkan adresleri application.yml'a yaz

# 3. AI servisi (ayrı terminal)
cd IbisSupply/ai
python -m uvicorn main:app --port 8000

# 4. Backend (ayrı terminal)
cd IbisSupply/backend
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

## Test Kullanıcıları
| Email | Şifre | Rol |
|-------|-------|-----|
| admin@ibissupply.com | admin123 | ADMIN |
| producer@ibissupply.com | producer123 | PRODUCER |

## Blockchain Adresleri (son deploy — node yeniden başlarsa değişir)
| Contract | Adres |
|----------|-------|
| RoleManager | 0x5FbDB2315678afecb367f032d93F642f64180aa3 |
| BatchRegistry | 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 |
| ShipmentRegistry | 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 |
| QualityRegistry | 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 |
| FarmRegistry | 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 |

## Tamamlanan Modüller

### Backend
- JWT Auth (login, refresh, register) — `AuthController`
- `JwtAuthFilter`: email principal, `ROLE_` prefix yok (sadece `ADMIN`, `PRODUCER` vs.)
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
- `RoleManager.sol` — rol yönetimi
- `BatchRegistry.sol` — batch kayıt
- `ShipmentRegistry.sol` — sevkiyat + teslimat
- `QualityRegistry.sol` — kalite kontrol
- `FarmRegistry.sol` — tarımsal kayıt
- Deploy script: `blockchain/scripts/deploy.js`, adresleri `deployed-addresses.json`'a kaydeder

### AI (Python FastAPI — port 8000)
- `anomaly_model.py`: RandomForest + rule-based hybrid, 600 sentetik veri, `model.pkl`
- `main.py`: 5 endpoint — `/ai/analyze-anomaly`, `/ai/risk-score`, `/ai/demo-anomaly`, `/ai/shelf-life/{category}`, `/ai/shelf-life`
- 8 ürün kategorisi için güvenli sıcaklık aralıkları + raf ömrü standartları (Türk Gıda Kodeksi)
- `SHELF_LIFE_STANDARDS`: MEAT/FISH/DAIRY/FROZEN/VEGETABLE/FRUIT/BAKERY/DRY_GOODS için optimal_days
- `requirements.txt`: Python 3.14 uyumlu versiyonlar (`numpy>=2.2.0`, `scikit-learn>=1.6.0`)

### Flutter
- Login ekranı + Register ekranı — dark navy glassmorphism, animasyonlu
- Splash screen — dark navy gradient, logo.png
- Dashboard — rol bazlı menü kartları (CUSTOMER: Ürünlerim, Şikayet; PRODUCER: + Tarımsal Kayıtlar)
- AppTheme — mavi (primary: `0xFF1565C0`)
- GoRouter: `/splash`, `/login`, `/register`, `/dashboard`, `/qr-public`, `/batches`, `/shipments`, `/quality-checks`, `/admin/users`, `/product-trace/:batchCode`, `/my-products`, `/complaint`, `/farm-records`, `/farm-records/create`, `/alerts`, `/profile`
- Batch ekranları: list, create (ürün seçilince raf ömrü API'den çekip expiry date otomatik doldurulur), detail (QR + TX hash)
- Shipment ekranları: list, create, detail (event timeline + CHECKPOINT + TEMPERATURE_LOG dialog + AI anomali banner)
- Kalite kontrol ekranları: list, create
- Admin ekranları: kullanıcı listesi, kullanıcı oluştur
- Customer ekranları: MyProductsScreen (favoriler), ComplaintScreen (şikayet)
- Farm Record ekranları: list (PRODUCER'a özel), create, detail (tüm alanlar + blockchain TX hash)
- Alerts ekranı: aktif/çözüldü ayrımı, severity renk kodlama, "Çözüldü" butonu
- Profile ekranı: renk kodlu avatar + initials, rol badge, e-posta/kuruluş/rol bilgisi, şifre değiştir dialog (placeholder), çıkış yap
- Dashboard header avatara tıklanınca `/profile` açılır
- `ShipmentDetailScreen`: AI anomali banner (CRITICAL/HIGH/MEDIUM/LOW renk kodlu)
- `ProductTraceScreen`: blockchain TX hash kartı + şikayet butonu
- Emülatör için `api_client.dart` → `http://10.0.2.2:8080/api/v1`

## Bilinen Bug
- **JWT 403 sorunu**: Spring Security, süresi dolmuş token için 401 değil 403 döndürüyor. `ApiClient` interceptor'ı sadece 401'de refresh yapıyor → 15 dk sonra tüm API çağrıları "Yüklenemedi" hatası veriyor. Kalıcı fix: `SecurityConfig`'e `AuthenticationEntryPoint` ekleyip 401 döndür, VEYA `ApiClient`'ta 403'ü de refresh dene.

## Demo Senaryosu (Hazır — 2026-04-09)
**"Organik Çilek Soğuk Zincir İhlali"**
- Batch: `BTCH-202604081529-7360` (Organik Çilek, FRUIT kategorisi)
- Shipment: `SHIP-202604091332-9982` — Muğla → İstanbul
- Events: DEPARTED(4.2°C) → CHECKPOINT(4.8°C) → TEMP_LOG(7.8°C⚠) → TEMP_LOG(9.5°C🔴) → CHECKPOINT(5.1°C) → DELIVERED
- AI Sonuç: `isAnomaly: true`, `riskLevel: MEDIUM`, `riskScore: 34.8`, `anomalyType: ANOMALOUS_PATTERN`
- Kalite: `NEEDS_REVIEW`

## Yapılacaklar
1. **JWT 403 bug fix** — `SecurityConfig`'e `AuthenticationEntryPoint` ekle (401 döndür) + `ApiClient`'ta 403'ü de handle et; yoksa oturum 15 dk sonra bozuluyor
2. **Şifre Değiştir** — backend endpoint yok (`PUT /api/v1/user/password`), `ProfileScreen`'daki dialog şu an placeholder ("yakında eklenecek")
3. **QR Okutma testi** — `QrPublicScreen` kamera ile çalışıyor mu kontrol et *(ertelendi)*
4. **Rapor yazımı** *(ertelendi)*
