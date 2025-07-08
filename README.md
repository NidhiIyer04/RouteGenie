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

## Backend Setup (Ubuntu / WSL)

1. Clone the project and move to backend folder:

```bash
cd ~/StudioProjects/RouteGenie/routegenie-backend
```

2. Create and activate a virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
```

3. Install dependencies:

```bash
pip install fastapi uvicorn aiohttp requests pydantic
```

4. (Optional) Set up Google Maps API key:

```bash
export GOOGLE_MAPS_API_KEY=your_api_key_here
```

5. Run the backend server:

```bash
uvicorn main:app --reload
```

6. Access:

* API Docs: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
* Health check: [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)

---

## Folder Structure

```
routegenie/
├── routegenie-backend/
│   ├── main.py
│   ├── core/
│   ├── routes/
│   ├── utils/
│   ├── data/
│   └── api_spec.md
├── routegenie-frontend/      # Optional (Flutter app goes here)
└── README.md
```

---
