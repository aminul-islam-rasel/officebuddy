# Office Buddy - Work Tracking App

A professional, offline-first Flutter application for tracking daily work hours and generating productivity reports.

## Features

- **Offline-First**: All data stored locally using Hive database
- **Daily Work Tracking**: Add, edit, and manage work entries with project details
- **Analytics Dashboard**: Visual charts and insights using FL Chart
- **PDF Reports**: Generate and share monthly and project-wise PDF reports
- **Modern UI**: Material 3 design with dark/light theme support
- **Responsive**: Optimized for mobile devices

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **Hive**: Local NoSQL database for offline storage
- **Provider**: State management
- **FL Chart**: Data visualization
- **PDF**: Report generation
- **Material 3**: Modern design system

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd officebuddy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

#### Android APK
```bash
flutter build apk --release
```

#### iOS (on macOS)
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── core/                 # Constants and utilities
├── models/              # Data models (WorkEntry)
├── services/            # Business logic services
├── database/            # Hive database setup
├── providers/           # State management (Provider)
├── screens/             # UI screens
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── add_work_screen.dart
│   ├── work_list_screen.dart
│   ├── analytics_screen.dart
│   └── settings_screen.dart
├── widgets/             # Reusable UI components
├── utils/               # Helper utilities
├── pdf/                 # PDF generation
└── theme/               # App theming
```

## Key Features Implementation

### Data Storage
- Uses Hive for local storage
- WorkEntry model with fields: id, date, projectName, workedHours, details, createdAt
- Automatic data persistence and synchronization

### State Management
- Provider pattern for reactive UI updates
- Separate providers for theme and work data
- Efficient data flow and UI responsiveness

### PDF Generation
- Monthly reports with project breakdown
- Project-specific reports with detailed entries
- Professional formatting with tables and summaries
- Share functionality for easy distribution

### Analytics
- Pie chart for project distribution
- Bar chart for project hours
- Summary statistics and insights

## Permissions

The app requires the following permissions:

### Android
- `WRITE_EXTERNAL_STORAGE`: For saving PDF reports
- `READ_EXTERNAL_STORAGE`: For sharing files

### iOS
- No additional permissions required for basic functionality

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team

---

**WorkLog Pro** - Track your productivity, boost your efficiency!
