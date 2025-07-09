# RouteGenie

RouteGenie is an AI-powered last-mile delivery optimization system designed to reduce delivery time, cost, and inefficiencies in urban and semi-urban logistics. Developed as part of Walmart Sparkathon, the system provides intelligent route planning using heuristics, traffic data, and vehicle constraints, and is designed to be integrated with a Flutter-based mobile frontend.

The backend is built with FastAPI and Python, and the frontend is built using Flutter and Android Studio.

---

## Problem Statement

In last-mile logistics, inefficient delivery routing leads to increased fuel consumption, delivery delays, and suboptimal resource usage. Traditional routing systems often ignore real-time traffic, road restrictions, delivery size, and vehicle types.

RouteGenie addresses these issues by combining custom optimization algorithms with map APIs and delivery-specific constraints. It aims to help delivery partners choose the most efficient route — not just the shortest.

---

## Features

* Optimize routes based on:

    * Distance
    * Time (with optional traffic)
    * Vehicle type and capacity
    * Delivery point priority
    * Road type (favoring major roads)
* Google Maps API integration (with mock fallback)
* REST API for route optimization
* Flutter frontend integration ready

---

## Tech Stack

| Component    | Technology                              |
| ------------ | --------------------------------------- |
| Backend      | Python 3.10, FastAPI                    |
| Optimization | Custom Dijkstra / Haversine-based logic |
| Maps API     | Google Maps Distance Matrix (or mock)   |
| Frontend     | Flutter, Dart, Android Studio           |
| Data Format  | JSON via REST API                       |

---

# RouteGenie Flutter App Setup Instructions

## Prerequisites

- Flutter SDK (>=3.10.0)
- Android Studio with Android SDK
- A Google Maps API key
- Your FastAPI backend running locally

## Step 1: Create Flutter Project

```bash
flutter create route_genie
cd route_genie
```

## Step 2: Organize Files

Based on your project structure, place the files as follows:

```
route_genie/
├── frontend/
│   ├── main.dart                  # Replace with provided code
│   ├── models.dart                # Replace with provided code
│   └── screens/
│       ├── home_screen.dart       # Replace with provided code
│       └── result_screen.dart     # Replace with provided code
├── backend/
│   └── main.py                    # Your existing FastAPI backend
├── pubspec.yaml                   # Replace with provided code
└── README.md                      # Your project documentation
```

**Important:** Since your Flutter files are in `frontend/` instead of `lib/`, you'll need to update the import statements in all Dart files.

### Update Import Statements:

**In `frontend/main.dart`:**
```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';  // Keep as is
```

**In `frontend/screens/home_screen.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models.dart';           // Keep as is
import 'result_screen.dart';       // Keep as is
```

**In `frontend/screens/result_screen.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models.dart';           // Keep as is
import 'dart:async';
```

## Alternative: Standard Flutter Structure

**Recommended approach** - Move your files to Flutter's standard `lib/` directory:

```bash
# From project root
mkdir lib
mkdir lib/screens

# Move files to standard Flutter locations
mv frontend/main.dart lib/
mv frontend/models.dart lib/
mv frontend/screens/home_screen.dart lib/screens/
mv frontend/screens/result_screen.dart lib/screens/

# Keep your backend folder as is
# backend/main.py stays in backend/
```

This approach is recommended because:
- It follows Flutter conventions
- No need to modify import statements
- Standard Flutter tooling works without issues
- Easier for other developers to understand

After moving files, your structure would be:
```
route_genie/
├── lib/                          # Standard Flutter source directory
│   ├── main.dart
│   ├── models.dart
│   └── screens/
│       ├── home_screen.dart
│       └── result_screen.dart
├── backend/
│   └── main.py                   # Your FastAPI backend
├── pubspec.yaml
└── README.md
```

## Step 3: Update pubspec.yaml

The provided `pubspec.yaml` includes all necessary dependencies:
- `http: ^1.1.0` for API calls
- `google_maps_flutter: ^2.5.0` for maps

## Step 4: Install Dependencies

```bash
flutter pub get
```

## Step 5: Configure Google Maps

### Android Configuration

1. **Get Google Maps API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable "Maps SDK for Android"
   - Create credentials (API Key)
   - Restrict the key to Android apps (optional but recommended)

2. **Add API Key to Android:**
   
   Edit `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application
       android:label="route_genie"
       android:name="${applicationName}"
       android:icon="@mipmap/ic_launcher">
       
       <!-- Add this meta-data tag -->
       <meta-data android:name="com.google.android.geo.API_KEY"
                  android:value="YOUR_API_KEY_HERE"/>
       
       <activity
           android:name=".MainActivity"
           android:exported="true"
           android:launchMode="singleTop"
           android:theme="@style/LaunchTheme"
           android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
           android:hardwareAccelerated="true"
           android:windowSoftInputMode="adjustResize">
           <!-- Intent filters here -->
       </activity>
   </application>
   ```

3. **Add Internet Permission:**
   
   In `android/app/src/main/AndroidManifest.xml`, add before `<application>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   ```

## Step 6: Update Backend URL

1. **Find your local IP address:**
   - Windows: `ipconfig` (look for IPv4 Address)
   - Mac/Linux: `ifconfig` or `ip addr show`

2. **Update the URL in `home_screen.dart`:**
   ```dart
   // Replace this line in home_screen.dart
   const String baseUrl = 'http://192.168.1.100:8000'; // Change to your IP
   ```

3. **Make sure your FastAPI backend allows CORS:**
   ```python
   # In your FastAPI backend, add:
   from fastapi.middleware.cors import CORSMiddleware
   
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

## Step 7: Run the App

1. **Start your FastAPI backend:**
   ```bash
   cd backend
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

2. **Connect Android device or start emulator**

3. **Run the Flutter app from project root:**
   ```bash
   flutter run
   ```

   **If using custom frontend directory structure:**
   ```bash
   flutter run --dart-define=FLUTTER_WEB_USE_SKIA=true
   ```

## Project Structure

```
route_genie/
├── frontend/
│   ├── main.dart
│   ├── models.dart
│   └── screens/
│       ├── home_screen.dart
│       └── result_screen.dart
├── backend/
│   └── main.py                    # Your FastAPI backend
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── pubspec.yaml
└── README.md
```

## Features Implemented

### Home Screen
- ✅ Vehicle type dropdown (van, truck, motorcycle)
- ✅ Fuel efficiency input field
- ✅ Start location selection
- ✅ Mock delivery points with size and priority
- ✅ Optimization goal radio buttons (time, distance, fuel)
- ✅ Consider traffic toggle
- ✅ Form validation
- ✅ Loading state during API call

### Result Screen
- ✅ Route summary card with distance, time, fuel cost
- ✅ Optimization score with progress indicator
- ✅ Interactive Google Maps with markers and polylines
- ✅ Delivery order list with step numbers
- ✅ Priority-based color coding
- ✅ Segment details (distance and duration)

### API Integration
- ✅ HTTP POST request to `/optimize` endpoint
- ✅ Proper JSON payload formatting
- ✅ Response parsing and error handling
- ✅ Loading states and error dialogs

## Testing

1. **Test without backend:** The app will show an error dialog if the backend is not running.

2. **Test with backend:** Make sure your FastAPI backend is running and accessible from your device.

3. **Test different scenarios:**
   - Different vehicle types
   - Different optimization goals
   - Toggle traffic consideration
   - Try different fuel efficiency values

## Troubleshooting

### Common Issues:

1. **Maps not showing:**
   - Check if Google Maps API key is correctly added
   - Verify API key has Maps SDK for Android enabled
   - Check internet connectivity

2. **API calls failing:**
   - Verify backend URL is correct
   - Check if backend is running and accessible
   - Ensure CORS is properly configured in backend
   - Check network connectivity

3. **Build errors:**
   - Run `flutter clean` and `flutter pub get`
   - Check if all dependencies are properly installed

4. **Permission errors:**
   - Verify internet and location permissions are added to AndroidManifest.xml

### Debug Commands:

```bash
# Check Flutter doctor
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check logs
flutter logs
```

## Customization Options

### Adding More Delivery Points:
Edit the `_deliveryPoints` list in `home_screen.dart` to add more mock delivery points.

### Styling:
- The app uses Material 3 design
- Colors can be customized in `main.dart` theme
- Card layouts can be modified in respective screen files

### Additional Features:
- Add real-time location picker
- Implement delivery point management (add/remove)
- Add route sharing functionality
- Implement offline caching

## Security Notes

- Never commit your Google Maps API key to version control
- Consider using environment variables for API keys
- Implement proper API key restrictions in Google Cloud Console
- Use HTTPS in production environments
