# Floral Billing Refined (Flutter + Hive, Web-ready)

**Tabs:** Billing, Products, Reports, Settings.

- Products support **pcs & kg**, with **Selling** and **Cost** price and stock.
- Billing includes **Customer Name**, **Phone**, **Payment Method** (Cash/Card/UPI), updates stock, and stores profit.
- Reports show **Daily / Monthly / Yearly** Revenue, Profit, and Invoice count.
- Settings provides **Backup/Restore JSON** that works on mobile and web (simple file dialog).

## Generate Hive Adapters
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Run (Web or Mobile)
```bash
# Web
flutter run -d chrome

# Android (example)
flutter run -d emulator-5554
```

> Default login is **admin / admin123** (seeded on first launch).
