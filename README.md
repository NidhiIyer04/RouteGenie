# RouteGenie

RouteGenie is an route optimization app designed to help logistics managers, dispatchers, and delivery drivers plan the most efficient delivery routes. It allows users to input delivery points, select a vehicle type, and choose optimization preferences like minimizing time, distance, or fuel cost. The app then communicates with a backend powered by machine learning and real-time traffic data to generate an optimized delivery route. RouteGenie is especially useful for last-mile delivery scenarios, helping businesses save time, reduce operational costs, and improve customer satisfaction by making deliveries faster and smarter.

## Features
- Add and manage delivery points
- Optimize routes by time, distance, or fuel
- Visualize routes on Google Maps
- Secure API key management with local properties

## Getting Started

### Frontend (Flutter)
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/RouteGenie.git
   cd RouteGenie/frontend_new
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Add your local config:

   ```
   # android/local.properties
   MAPS_API_KEY=your_google_maps_api_key
   ```

4. Run the app:

   ```bash
   flutter run
   ```

---

### Backend (FastAPI / Python)

1. Navigate to the backend directory:

   ```bash
   cd ../backend
   ```

2. (Optional) Create and activate a virtual environment:

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

4. Run the server:

   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

---

## Notes

* `.env` and `android/local.properties` are **gitignored** to keep secrets safe.
* Uses `flutter_dotenv` and Gradle `resValue` to load API keys securely.

