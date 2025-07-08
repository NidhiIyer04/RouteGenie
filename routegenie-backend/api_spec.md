# RouteGenie API Specification

## Overview
RouteGenie is an AI-powered backend service for optimizing last-mile delivery routes. This API provides endpoints for route optimization and sample data retrieval.

**Base URL:** `http://localhost:8000`

## Authentication
Currently, no authentication is required (development mode).

## Endpoints

### 1. GET `/`
**Description:** Root endpoint with API information.

**Response:**
```json
{
  "message": "RouteGenie API is running!",
  "version": "1.0.0",
  "endpoints": ["/optimize", "/sample-data", "/docs"]
}
```

### 2. POST `/optimize`
**Description:** Optimize delivery route based on delivery points and constraints.

**Request Body:**
```json
{
  "delivery_points": [
    {
      "id": "delivery_1",
      "lat": 17.3850,
      "lon": 78.4867,
      "address": "123 Main St, Hyderabad",
      "size": "medium",
      "priority": 2,
      "time_window_start": "09:00",
      "time_window_end": "17:00"
    }
  ],
  "vehicle": {
    "type": "van",
    "capacity": "medium",
    "fuel_efficiency": 12.5
  },
  "start_location": {
    "id": "warehouse",
    "lat": 17.4065,
    "lon": 78.4772,
    "address": "Warehouse, Hyderabad",
    "size": "large",
    "priority": 1
  },
  "consider_traffic": true,
  "optimization_goal": "time"
}
```

**Request Parameters:**
- `delivery_points` (array): List of delivery locations
    - `id` (string): Unique identifier
    - `lat` (float): Latitude
    - `lon` (float): Longitude
    - `address` (string): Full address
    - `size` (string): Package size ("small", "medium", "large")
    - `priority` (integer): Priority level (1-5, where 1 is highest)
    - `time_window_start` (string, optional): Start time for delivery window
    - `time_window_end` (string, optional): End time for delivery window

- `vehicle` (object): Vehicle specifications
    - `type` (string): Vehicle type ("van", "truck", "motorcycle")
    - `capacity` (string): Vehicle capacity ("small", "medium", "large")
    - `fuel_efficiency` (float): Fuel efficiency in km/liter

- `start_location` (object): Starting point (warehouse/depot)
- `consider_traffic` (boolean): Whether to factor in traffic conditions
- `optimization_goal` (string): Optimization objective ("time", "distance", "fuel")

**Response:**
```json
{
  "route_order": ["warehouse", "delivery_1", "delivery_2", "delivery_3"],
  "segments": [
    {
      "from_point": "warehouse",
      "to_point": "delivery_1",
      "distance_km": 5.2,
      "duration_minutes": 15,
      "traffic_delay_minutes": 3
    }
  ],
  "total_distance_km": 25.7,
  "total_time_minutes": 85,
  "estimated_fuel_cost": 180.50,
  "optimization_score": 0.87
}
```

**Response Fields:**
- `route_order`: Optimal sequence of delivery points
- `segments`: Individual route segments with distances and times
- `total_distance_km`: Total route distance
- `total_time_minutes`: Total estimated time including traffic
- `estimated_fuel_cost`: Estimated fuel cost in local currency
- `optimization_score`: Algorithm confidence score (0-1)

### 3. GET `/sample-data`
**Description:** Returns sample delivery data for testing Flutter UI.

**Response:**
```json
{
  "sample_requests": [
    {
      "delivery_points": [...],
      "vehicle": {...},
      "start_location": {...}
    }
  ],
  "sample_locations": [
    {
      "id": "loc_1",
      "name": "Hyderabad Central",
      "lat": 17.3850,
      "lon": 78.4867,
      "address": "Hyderabad Central, Punjagutta"
    }
  ]
}
```

### 4. GET `/health`
**Description:** Health check endpoint for monitoring.

**Response:**
```json
{
  "status": "healthy",
  "services": {
    "route_optimizer": "active",
    "google_maps": "active"
  }
}
```

## Error Responses

All endpoints return standard HTTP status codes:

- `200`: Success
- `400`: Bad Request
- `404`: Not Found
- `500`: Internal Server Error

**Error Response Format:**
```json
{
  "detail": "Error message describing what went wrong"
}
```

## Common Error Scenarios

1. **Insufficient Delivery Points** (400)
    - At least 2 delivery points are required for optimization

2. **Invalid Coordinates** (400)
    - Latitude must be between -90 and 90
    - Longitude must be between -180 and 180

3. **Google Maps API Error** (500)
    - API quota exceeded or invalid API key
    - Service temporarily unavailable

## Flutter Integration Notes

### Required Dependencies
Add these to your Flutter `pubspec.yaml`:
```yaml
dependencies:
  http: ^0.13.5
  geolocator: ^9.0.2
  google_maps_flutter: ^2.2.3
```

### Sample Flutter HTTP Client
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteGenieClient {
  static const String baseUrl = 'http://localhost:8000';
  
  static Future<Map<String, dynamic>> optimizeRoute(
    Map<String, dynamic> request
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/optimize'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to optimize route');
    }
  }
  
  static Future<Map<String, dynamic>> getSampleData() async {
    final response = await http.get(Uri.parse('$baseUrl/sample-data'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sample data');
    }
  }
}
```

## Testing the API

### Using cURL
```bash
# Test optimization endpoint
curl -X POST http://localhost:8000/optimize \
  -H "Content-Type: application/json" \
  -d @test_request.json

# Get sample data
curl http://localhost:8000/sample-data
```

### Using Python requests
```python
import requests

# Test optimization
response = requests.post(
    'http://localhost:8000/optimize',
    json={
        "delivery_points": [...],
        "vehicle": {...},
        "start_location": {...}
    }
)
print(response.json())
```

## Development Setup

1. Install dependencies:
   ```bash
   pip install fastapi uvicorn requests
   ```

2. Run the server:
   ```bash
   python main.py
   ```

3. Access interactive docs at: `http://localhost:8000/docs`

## Environment Variables

Set these environment variables for full functionality:
- `GOOGLE_MAPS_API_KEY`: Your Google Maps API key
- `ENVIRONMENT`: Set to "production" for production deployment