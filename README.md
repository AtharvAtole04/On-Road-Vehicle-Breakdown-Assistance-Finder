# On-Road Vehicle Breakdown Assistance Finder

A cross-platform mobile application built with **Flutter**, **GetX**, and **Firebase** designed to provide on-demand roadside assistance and connect drivers with nearby mechanics.

---

## Features

- **Driver & Mechanic Portals:** Separate roles and custom dashboards for drivers, mechanics, and administrators.
- **Real-Time Booking & Tracking:** On-demand assistance requests with OpenStreetMap integration and live order tracking.
- **Authentication & Role Management:** Firebase Authentication with role-based routing (Driver, Mechanic, Admin).
- **Wallet & Transactions:** In-app wallet management and transaction tracking.
- **Feedback & Grievances:** Review system for completed assistance orders and grievance reporting.

---

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management & Routing:** [GetX](https://pub.dev/packages/get)
- **Backend & Database:** [Firebase Core](https://firebase.google.com/), Cloud Firestore, Firebase Authentication
- **Mapping & Geolocation:** [flutter_map](https://pub.dev/packages/flutter_map), [geolocator](https://pub.dev/packages/geolocator), [latlong2](https://pub.dev/packages/latlong2)

---

## Getting Started

### Prerequisites

- Flutter SDK (>= 2.18.0 < 4.0.0)
- Android Studio / Xcode (for device emulation/deployment)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AtharvAtole04/On-Road-Vehicle-Breakdown-Assistance-Finder.git
   cd On-Road-Vehicle-Breakdown-Assistance-Finder
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Place your `google-services.json` inside `android/app/`
   - Configure Firebase options if targeting iOS/Web via FlutterFire CLI.

4. **Run the application:**
   ```bash
   flutter run
   ```
