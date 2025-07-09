# RouteGenie
AI-Optimized Last-Mile Delivery Backend

This repository contains the backend service for RouteGenie, an intelligent route optimization system designed for last-mile logistics. The backend is built using FastAPI (Python) and provides a REST API that accepts delivery points and vehicle details, then returns an optimized delivery path. It integrates with mock or real Google Maps data and is designed to interface with a Flutter frontend.

## Setup Instructions

This guide assumes you are using linux inside Android Studio's terminal.

## 1. Navigate to the Backend Project

```bash
git clone https://github.com/NidhiIyer04/RouteGenie.git
cd RouteGenie/routegenie-backend
```

## 2. Create and Activate Python Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

## 3. Install Dependencies

```bash
pip install fastapi uvicorn aiohttp pydantic requests
```

## 4. Run the Backend Server

```bash
uvicorn main:app --reload
```

Open your browser and go to:

* Swagger UI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
* Health check: [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)


## Project Directory Structure

```
routegenie-backend/
├── main.py                   # FastAPI entry point
├── core/
│   └── optimizer.py          # Route optimization logic
├── routes/
│   └── optimizer.py          # API endpoint logic
├── utils/
│   └── google_maps.py        # Distance matrix logic (mock + real)
├── data/
│   └── mock_deliveries.json  # Sample delivery data
├── api_spec.md               # API specification for frontend integration
├── venv/                     # Python virtual environment
└── README.md
```

## API Overview (to Use in Flutter)

Base URL: [http://127.0.0.1:8000/api](http://127.0.0.1:8000/api)

### POST /optimize

Accepts a list of delivery points and returns an optimized route.

## Local Testing

To test the distance matrix logic independently:

```bash
python utils/google_maps.py
```

This will load data/mock\_deliveries.json and return a mocked distance matrix.

## Next Steps Flutter Developer

1. Set up a new Flutter app in Android Studio.
2. Add required dependencies: http, google\_maps\_flutter, etc.
3. Build UI:

    * A form or list view to input delivery points
    * A map view to render route lines and pins
    * A summary card with distance, time, and delay info
4. Call the backend POST /api/optimize and parse the response.
5. Use returned lat/lon points to render the optimized path using polylines.

For API integration support, refer to the Swagger docs at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
