# Rootery App

Flutter-based IoT application for dehydrator management with real-time monitoring and marketplace features, powered by Supabase backend.

## ðŸŒŸ Features

- **Real-time Monitoring**: Live sensor data updates (temperature, humidity, airflow)
- **Dehydrator Control**: Start/stop drying operations with auto/manual modes
- **Marketplace**: Browse and purchase dehydrated products with shopping cart
- **Batch Reports**: Historical data and analytics for drying operations
- **Role-based Access**: Farmer, Admin, and Buyer dashboards
- **ESP32 Integration**: IoT device connectivity for hardware control
- **Supabase Backend**: Real-time database, authentication, and API

## ðŸ“ Project Structure

```
rootery_app/
â”œâ”€â”€ lib/
â”‚   â”œâ”€â”€ main.dart                    # App entry point
â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â””â”€â”€ app_models.dart          # Data models (Product, SensorData, etc.)
â”‚   â”œâ”€â”€ services/
â”‚   â”‚   â”œâ”€â”€ supabase_service.dart    # Supabase API wrapper
â”‚   â”‚   â”œâ”€â”€ data_service.dart        # Data management with real-time streams
â”‚   â”‚   â””â”€â”€ auth_service.dart        # Authentication service
â”‚   â”œâ”€â”€ screens/
â”‚   â”‚   â”œâ”€â”€ splash_screen.dart       # Animated splash screen
â”‚   â”‚   â”œâ”€â”€ login/
â”‚   â”‚   â”‚   â””â”€â”€ login_screen.dart    # Login with role-based routing
â”‚   â”‚   â”œâ”€â”€ dashboard/
â”‚   â”‚   â”‚   â”œâ”€â”€ farmer_dashboard.dart # Real-time sensor dashboard
â”‚   â”‚   â”‚   â””â”€â”€ controls_screen.dart  # Dehydrator controls
â”‚   â”‚   â”œâ”€â”€ admin/
â”‚   â”‚   â”‚   â””â”€â”€ admin_dashboard.dart  # Admin system overview
â”‚   â”‚   â”œâ”€â”€ marketplace_screen.dart   # Product marketplace with cart
â”‚   â”‚   â”œâ”€â”€ reports_screen.dart       # Batch history and analytics
â”‚   â”‚   â”œâ”€â”€ settings_screen.dart      # User settings
â”‚   â”‚   â””â”€â”€ feedback_screen.dart      # Feedback form
â”‚   â””â”€â”€ theme/
â”‚       â””â”€â”€ rootery_theme.dart       # App theme colors
â”œâ”€â”€ SUPABASE_SCHEMA.md               # Database schema (SQL)
â”œâ”€â”€ SUPABASE_SETUP.md                # Setup instructions
â””â”€â”€ README.md                        # This file
```

## ðŸš€ Quick Start

### Prerequisites

- Flutter SDK 3.38.1 or higher
- Dart 3.10.0 or higher
- Supabase account (free tier works)

### 1. Install Dependencies

```bash
cd rootery_app
flutter pub get
```

### 2. Set Up Supabase

Follow the complete guide in `SUPABASE_SETUP.md`:

1. Create Supabase project at https://supabase.com
2. Run SQL schema from `SUPABASE_SCHEMA.md` in SQL Editor
3. Copy your Project URL and Anon Key
4. Update credentials in `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_ANON_KEY',
);
```

### 3. Create Test User

In Supabase dashboard:
1. Authentication â†’ Users â†’ Add user
   - Email: `farmer@test.com`
   - Password: `test123456`

2. Table Editor â†’ users â†’ Insert row
   - id: [UUID from auth.users]
   - email: `farmer@test.com`
   - name: Test Farmer
   - role: Farmer

### 4. Run the App

```bash
flutter run -d chrome    # Web
flutter run -d windows   # Windows
flutter run -d android   # Android
flutter run -d ios       # iOS
```

## ðŸŽ¨ App Flow

1. **Splash Screen** (3s animation) â†’ Login
2. **Login** â†’ Role-based routing:
   - Farmer â†’ Farmer Dashboard (real-time sensors)
   - Admin â†’ Admin Dashboard (system overview)
   - Buyer â†’ Marketplace (shopping)
3. **Navigation**: Bottom nav or drawer to access all features

## ðŸ“Š Data Models

### Product
Marketplace items with name, price, category, stock, rating

### SensorData
Live readings: temperature, humidity, airflow, fan speed, heater status, solar intensity

### DryingBatch
Historical records: crop, weight, duration, moisture levels, status

### DryingProgress
Active operations: batch ID, progress %, estimated time, moisture tracking

### User
Profile: email, name, role, phone, farm

## ðŸ” Authentication

- Email/password authentication via Supabase
- Role-based access control (Farmer, Admin, Buyer)
- Row Level Security (RLS) policies on all tables
- Session management with auto-refresh

## ðŸ”„ Real-time Features

- Sensor data updates every 3 seconds
- Drying progress updates every 3 seconds
- Real-time subscriptions via Supabase (optional, polling as fallback)
- Shopping cart with instant updates

## ðŸ“¦ Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  supabase_flutter: ^2.10.3     # Backend integration
  http: ^1.6.0                  # HTTP requests
  flutter_secure_storage: ^9.2.4 # Secure storage
  provider: ^6.1.5              # State management
```

## ðŸŽ¨ Theme

- **Background**: #071B0C (dark green)
- **Accent Green**: #34C759
- **Light Green**: #9ACD32
- **Card**: #1B4D3E (dark green)
- **Splash**: #0D2847 (dark blue), #FFC107 (amber progress)

## ðŸ› ï¸ Development

### Run Tests

```bash
flutter test
```

### Build for Production

```bash
flutter build web         # Web
flutter build windows     # Windows
flutter build apk         # Android
flutter build ios         # iOS
```

### Clean Build

```bash
flutter clean
flutter pub get
flutter run
```

## ðŸ“± Screens Overview

### Splash Screen
- Animated logo with golden arc + green leaf
- Progress bar animation
- 3-second duration

### Farmer Dashboard
- 6 live sensor cards (temp, humidity, airflow, fan, heater, solar)
- Current batch progress with percentage
- Start/Stop drying controls
- Navigation to Controls, Reports, Marketplace

### Controls Screen
- Auto Mode: Crop selection, AI recommendations
- Manual Mode: Temperature/airflow sliders, time inputs
- Mode toggle between auto/manual

### Marketplace
- Product grid with search and category filters
- Shopping cart with add/remove items
- Product details modal
- Checkout flow

### Reports
- Summary stats: Total batches, weight, avg duration
- Batch history cards with status, date, metrics
- Filterable by crop type and date range

### Admin Dashboard
- System statistics: Users, devices, transactions
- User management
- Settings and configuration

## ðŸ”§ ESP32 Integration (Planned)

See `SUPABASE_SCHEMA.md` for sensor_data table structure.

ESP32 should:
1. Authenticate with Supabase
2. POST sensor readings to `sensor_data` table every 3 seconds
3. Listen for control commands (start/stop, temperature, fan speed)

## ðŸ› Troubleshooting

### "No rows found"
- Insert sample data from `SUPABASE_SCHEMA.md`

### Real-time not working
- Enable replication for sensor_data and drying_progress tables in Supabase dashboard

### Authentication fails
- Check Supabase URL and anon key in main.dart
- Ensure user exists in both auth.users and users tables

### Connection errors
- Verify internet connection
- Check if Supabase project is active (not paused)

## ðŸ“š Documentation

- [Supabase Setup Guide](SUPABASE_SETUP.md)
- [Database Schema](SUPABASE_SCHEMA.md)
- [Flutter Docs](https://docs.flutter.dev/)
- [Supabase Docs](https://supabase.com/docs)

## ðŸ¤ Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## ðŸ“„ License

This project is licensed under the MIT License.

## ðŸ‘¥ Team

Developed for IoT-based dehydrator management and marketplace platform.

## ðŸ“ž Support

For issues and questions:
- Check `SUPABASE_SETUP.md` for setup help
- Open GitHub issue
- Contact: [Your contact info]

---

**Version**: 1.0.0  
**Last Updated**: November 2025  
**Platform**: Flutter (Web, Android, iOS, Windows, Linux, macOS)

