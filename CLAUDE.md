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
| AI | Python FastAPI + scikit-learn (henüz başlanmadı) |

## Çalışma Kuralları
- Backend önce yaz, sonra Flutter — API contract olmadan form field'ları kurulamaz
- `mvn clean package -DskipTests` ile build, `java -jar target/backend-0.0.1-SNAPSHOT.jar` ile başlat
- NetBeans Lombok hataları (`cannot find symbol: builder()`) gerçek değil — Maven derleme çalışır
- Commit mesajlarına `Co-Authored-By` satırı ekleme
- Terminal komutlarını kendin çalıştır, kullanıcıya bırakma

## Test Kullanıcıları
| Email | Şifre | Rol |
|-------|-------|-----|
| admin@ibissupply.com | admin123 | ADMIN |
| producer@ibissupply.com | producer123 | PRODUCER |

## Tamamlanan Modüller

### Backend
- JWT Auth (login, refresh) — `AuthController`
- `JwtAuthFilter`: email principal, `ROLE_` prefix yok (sadece `ADMIN`, `PRODUCER` vs.)
- `ProductController` — `GET /api/v1/products`
- `BatchController` — `POST/GET /api/v1/batches`, status update
- `ShipmentController` — `POST/GET /api/v1/shipments`, events, deliver
- `DataInitializer`: admin + producer user + 3 ürün seed (Domates/Elma/Süt)

### Flutter
- Login ekranı — dark navy glassmorphism, animasyonlu
- Splash screen — dark navy gradient, logo.png
- Dashboard — rol bazlı menü kartları
- AppTheme — mavi (primary: `0xFF1565C0`)
- GoRouter: `/splash`, `/login`, `/dashboard`, `/qr-public`, `/batches`, `/shipments`
- Batch ekranları: list, create, detail (QR göster)
- Shipment ekranları: list, create, detail (event timeline)

## Yapılacaklar (Sırasıyla)
1. **QR Okutma + Tüketici Sorgu** — `GET /api/v1/trace/{batchCode}` + Flutter QR scanner
2. **Kalite Kontrol** — Inspector rolü, kontrol kaydı
3. **Admin Ekranı** — kullanıcı yönetimi
4. **Blockchain Bridge** — batch/shipment olaylarını smart contract'a yaz
5. **Python AI Servisi** — anomali tespiti
6. **Push Notifications** — Firebase
