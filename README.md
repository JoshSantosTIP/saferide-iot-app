# SafeRide IoT App

### Contributors:
         rcpinca.it@tip.edu.ph

## Project Description
SafeRide is a mobile-based IoT safety monitoring system that prevents passenger overloading in jeepneys on routes like Montalban–Cubao. 

It uses load sensors, a microcontroller, and a mobile app to track passenger count in real time and alert drivers when capacity limits are reached.

This project serves as our final output, combining Flutter and IoT.

---

## Technologies Used
- Flutter
- Dart
- IoT Devices and Sensors
- Firebase

---

## Planned Features
- User authentication
- Real-time location and sensor monitoring
- Ride safety alerts and notifications
- Cloud-based data storage and analytics
- mobile application support

---

### Prerequisites
- Flutter and Dart SDK
- Git
- Android Studio or VS Code

## Installation & Setup Instructions

Follow these steps to set up the project locally.

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/saferide-iot-app.git
cd saferide-iot-app
```

### 2. Environment Variables & Secrets
Because this project uses Firebase and external APIs, the sensitive keys are intentionally **not** pushed to GitHub. You must request the secret files from the project owner (or your team lead) and place them in the correct directories before building.

1. **Obtain the secrets ZIP file** from your team lead.
2. Ensure you have the following files correctly placed:
   - Root directory: `.env` (contains the `ORS_API_KEY`)
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Flutter: `lib/firebase_options.dart`
   - Simulation: `simulation/config.js`

*Note: If you are setting this up from scratch, you can duplicate the existing `.example` files and fill them with your own API keys.*

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the Application
```bash
flutter run
```

---

## Running the Web Simulation
The project includes a web simulation tool to mock Jeepney IoT hardware data.

1. Navigate to the `simulation` folder.
2. Ensure you have copied/setup `config.js` with your Firebase API keys securely (reference `config.example.js`).
3. Open `register.html` in your browser to add a mock Jeepney.
4. Open `index.html` to control the mock vehicle's coordinates, passenger count, and weight. The Flutter app will react to these changes in real-time.
