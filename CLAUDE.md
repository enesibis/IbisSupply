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

## Tamamlanan Modüller

### Backend
- JWT Auth (login, refresh) — `AuthController`
- `JwtAuthFilter`: email principal, `ROLE_` prefix yok (sadece `ADMIN`, `PRODUCER` vs.)
- `ProductController` — `GET /api/v1/products`
- `BatchController` — `POST/GET /api/v1/batches`, status update
- `ShipmentController` — `POST/GET /api/v1/shipments`, events, deliver, `GET /{id}/anomaly`
- `QualityCheckController` — kalite kontrol kaydı
- `AdminController` — kullanıcı yönetimi
- `DataInitializer`: admin + producer user + 3 ürün seed (Domates/Elma/Süt)
- `BlockchainService`: Web3j bridge — batch/shipment/quality kayıtlarını Hardhat'a yazar, TX hash döner
- `AiService`: Python FastAPI'ye RestTemplate ile bağlanır — anomali analizi + risk skoru

### Blockchain (Solidity)
- `RoleManager.sol` — rol yönetimi
- `BatchRegistry.sol` — batch kayıt
- `ShipmentRegistry.sol` — sevkiyat + teslimat
- `QualityRegistry.sol` — kalite kontrol
- Deploy script: `blockchain/scripts/deploy.js`, adresleri `deployed-addresses.json`'a kaydeder

### AI (Python FastAPI — port 8000)
- `anomaly_model.py`: RandomForest + rule-based hybrid, 600 sentetik veri, `model.pkl`
- `main.py`: 3 endpoint — `/ai/analyze-anomaly`, `/ai/risk-score`, `/ai/demo-anomaly`
- 8 ürün kategorisi için güvenli sıcaklık aralıkları (MEAT, FISH, DAIRY, FROZEN, vs.)
- `requirements.txt`: Python 3.14 uyumlu versiyonlar (`numpy>=2.2.0`, `scikit-learn>=1.6.0`)

### Flutter
- Login ekranı — dark navy glassmorphism, animasyonlu
- Splash screen — dark navy gradient, logo.png
- Dashboard — rol bazlı menü kartları
- AppTheme — mavi (primary: `0xFF1565C0`)
- GoRouter: `/splash`, `/login`, `/dashboard`, `/qr-public`, `/batches`, `/shipments`, `/quality-checks`, `/admin/users`, `/product-trace/:batchCode`
- Batch ekranları: list, create, detail (QR göster)
- Shipment ekranları: list, create, detail (event timeline + CHECKPOINT + TEMPERATURE_LOG dialog)
- Kalite kontrol ekranları: list, create
- Admin ekranları: kullanıcı listesi, kullanıcı oluştur
- `ShipmentDetailScreen`: AI anomali banner (CRITICAL/HIGH/MEDIUM/LOW renk kodlu)
- `ShipmentBloc`: `LoadAnomalyResult` event → `AnomalyResultLoaded` state
- Emülatör için `api_client.dart` → `http://10.0.2.2:8080/api/v1`

## Yapılacaklar
1. **Batch Detail Ekranı** — blockchain TX hash gösterimi (demo için önemli)
2. **QR Okutma testi** — `QrPublicScreen` kamera ile çalışıyor mu kontrol et
3. **Demo Senaryosu** — "Organik Çilek" uçtan uca akış testi
4. **Rapor yazımı**
