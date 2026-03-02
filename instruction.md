# SafeRide IoT App Setup Instructions

Welcome to the SafeRide project! This guide will walk you through the process of cloning the repository, installing all necessary dependencies, and running both the Flutter application and the web-based simulation tools.

## Prerequisites

Before you begin, ensure you have the following software installed on your machine:

1.  **Git:** To clone the repository.
    *   [Download Git](https://git-scm.com/downloads)
2.  **Flutter SDK:** To build and run the mobile application.
    *   [Install Flutter](https://docs.flutter.dev/get-started/install)
    *   Verify your installation by running `flutter doctor` in your terminal and resolving any major issues.
3.  **An IDE/Text Editor:** We recommend [Visual Studio Code](https://code.visualstudio.com/) with the "Flutter" and "Dart" extensions installed, or Android Studio.
4.  **A Web Browser:** To run the simulation interface (e.g., Chrome, Edge, Firefox).

---

## Step 1: Clone the Repository

Open your terminal or command prompt and run the following command to download the project source code to your local machine:

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
```
*(Replace `<YOUR_GITHUB_REPOSITORY_URL>` with the actual URL of your project repository)*

Navigate into the newly created project folder:

```bash
cd saferide_iot_app
```

---

## Step 2: Install Flutter Dependencies

The mobile application relies on several Dart packages (like Firebase, Geolocator, FlutterMap, etc.). You need to download these packages before the app can be run.

Make sure you are in the root directory of the project (`saferide_iot_app`), and execute:

```bash
flutter pub get
```
This command reads the `pubspec.yaml` file and downloads all the required libraries into your project.

---

## Step 3: Run the Flutter Application

You can run the SafeRide mobile app on an Android Emulator, an iOS Simulator, or directly in a web browser using Flutter's web support.

1.  **Start your device/emulator** (or have Chrome ready).
2.  Run the following command:

```bash
flutter run
```

*Note: The app is pre-configured with Firebase credentials. It will automatically connect to the `saferide-iot-app` database.*

---

## Step 4: Run the Web Simulation Tools

The project includes a web-based simulation environment that lets you register new jeepneys and simulate their movement, passenger count, and weight in real time. Because these are pure HTML/JS files, you don't need a heavy local server to run them initially.

1.  Open your file explorer and navigate to the `simulation` folder inside the project.
2.  **To Register a Jeepney:** Double-click on `register.html` to open it in your default web browser. You can add new jeepneys with custom capacities and routes here.
3.  **To Simulate a Jeepney:** Double-click on `index.html` to open the simulation panel. Here, you can select any registered jeepney from the dropdown and modify its live GPS location, passenger count, and weight.

*Any changes you make in the Simulation Panel will instantly reflect in the Flutter mobile application in real-time!*
