from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from pathlib import Path
import json
import os

from core.optimizer import RouteOptimizer
from utils.google_maps import GoogleMapsClient

app = FastAPI(
    title="RouteGenie API",
    description="AI-powered backend service for last-mile delivery route optimization",
    version="1.0.0"
)

# Configure CORS for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
route_optimizer = RouteOptimizer()
google_maps_client = GoogleMapsClient()

# Pydantic models for request/response
class DeliveryPoint(BaseModel):
    id: str
    lat: float
    lon: float
    address: str
    size: str  # "small", "medium", "large"
    priority: int  # 1-5, where 1 is highest priority
    time_window_start: Optional[str] = None  # "09:00"
    time_window_end: Optional[str] = None    # "17:00"

class Vehicle(BaseModel):
    type: str  # "van", "truck", "motorcycle"
    capacity: str  # "small", "medium", "large"
    fuel_efficiency: float  # km per liter

class OptimizationRequest(BaseModel):
    delivery_points: List[DeliveryPoint]
    vehicle: Vehicle
    start_location: DeliveryPoint
    consider_traffic: bool = True
    optimization_goal: str = "time"  # "time", "distance", "fuel"

class RouteSegment(BaseModel):
    from_point: str
    to_point: str
    distance_km: float
    duration_minutes: int
    traffic_delay_minutes: int = 0

class OptimizedRoute(BaseModel):
    route_order: List[str]  # List of delivery point IDs in order
    segments: List[RouteSegment]
    total_distance_km: float
    total_time_minutes: int
    estimated_fuel_cost: float
    optimization_score: float

@app.get("/")
async def root():
    return {
        "message": "RouteGenie API is running!",
        "version": "1.0.0",
        "endpoints": ["/optimize", "/sample-data", "/docs"]
    }

@app.post("/optimize", response_model=OptimizedRoute)
async def optimize_route(request: OptimizationRequest):
    """
    Optimize delivery route based on provided delivery points and constraints.
    """
    try:
        if len(request.delivery_points) < 2:
            raise HTTPException(
                status_code=400,
                detail="At least 2 delivery points are required"
            )

        distance_matrix = await google_maps_client.get_distance_matrix(
            request.delivery_points + [request.start_location],
            consider_traffic=request.consider_traffic
        )

        optimized_route = route_optimizer.optimize(
            delivery_points=request.delivery_points,
            vehicle=request.vehicle,
            start_location=request.start_location,
            distance_matrix=distance_matrix,
            optimization_goal=request.optimization_goal
        )

        return optimized_route

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Optimization failed: {str(e)}")

@app.get("/sample-data")
async def get_sample_data():
    """
    Returns sample delivery data for testing Flutter UI.
    """
    try:
        data_path = Path(__file__).parent.parent / "data" / "mock_deliveries.json"
        data_path = data_path.resolve()

        with open(data_path, 'r') as f:
            sample_data = json.load(f)

        return sample_data

    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Sample data not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load sample data: {str(e)}")

@app.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring.
    """
    return {
        "status": "healthy",
        "services": {
            "route_optimizer": "active",
            "google_maps": "active" if google_maps_client.is_configured() else "mock_mode"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
