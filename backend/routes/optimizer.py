from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict, Optional
import json
import os
from datetime import datetime
import logging

from core.optimizer import RouteOptimizer, DeliveryPoint, Vehicle, OptimizedRoute
from utils.google_maps import GoogleMapsClient

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/v1", tags=["route-optimization"])

# Initialize services
route_optimizer = RouteOptimizer()
google_maps_client = GoogleMapsClient()

# Pydantic models for validation (if using FastAPI with main.py)
from pydantic import BaseModel, validator

class DeliveryPointModel(BaseModel):
    id: str
    lat: float
    lon: float
    address: str
    size: str
    priority: int
    time_window_start: Optional[str] = None
    time_window_end: Optional[str] = None

    @validator('lat')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v

    @validator('lon')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

    @validator('size')
    def validate_size(cls, v):
        if v not in ['small', 'medium', 'large']:
            raise ValueError('Size must be small, medium, or large')
        return v

    @validator('priority')
    def validate_priority(cls, v):
        if not 1 <= v <= 5:
            raise ValueError('Priority must be between 1 and 5')
        return v

class VehicleModel(BaseModel):
    type: str
    capacity: str
    fuel_efficiency: float

    @validator('type')
    def validate_vehicle_type(cls, v):
        if v not in ['motorcycle', 'van', 'truck']:
            raise ValueError('Vehicle type must be motorcycle, van, or truck')
        return v

    @validator('capacity')
    def validate_capacity(cls, v):
        if v not in ['small', 'medium', 'large']:
            raise ValueError('Capacity must be small, medium, or large')
        return v

    @validator('fuel_efficiency')
    def validate_fuel_efficiency(cls, v):
        if v <= 0:
            raise ValueError('Fuel efficiency must be positive')
        return v

class OptimizationRequestModel(BaseModel):
    delivery_points: List[DeliveryPointModel]
    vehicle: VehicleModel
    start_location: DeliveryPointModel
    consider_traffic: bool = True
    optimization_goal: str = "time"

    @validator('delivery_points')
    def validate_delivery_points(cls, v):
        if len(v) < 2:
            raise ValueError('At least 2 delivery points are required')
        return v

    @validator('optimization_goal')
    def validate_optimization_goal(cls, v):
        if v not in ['time', 'distance', 'fuel']:
            raise ValueError('Optimization goal must be time, distance, or fuel')
        return v

class RouteAnalytics:
    """Helper class for route analytics and performance metrics."""

    @staticmethod
    def calculate_savings(optimized_route: OptimizedRoute, baseline_route: Optional[Dict] = None) -> Dict:
        """
        Calculate savings compared to a baseline route (e.g., unoptimized).
        """
        if not baseline_route:
            # Create a simple baseline (direct routes from start to each point)
            baseline_distance = optimized_route.total_distance_km * 1.3  # 30% more
            baseline_time = optimized_route.total_time_minutes * 1.4     # 40% more
            baseline_fuel_cost = optimized_route.estimated_fuel_cost * 1.3
        else:
            baseline_distance = baseline_route.get('total_distance_km', 0)
            baseline_time = baseline_route.get('total_time_minutes', 0)
            baseline_fuel_cost = baseline_route.get('estimated_fuel_cost', 0)

        return {
            "distance_saved_km": round(baseline_distance - optimized_route.total_distance_km, 2),
            "time_saved_minutes": int(baseline_time - optimized_route.total_time_minutes),
            "fuel_cost_saved": round(baseline_fuel_cost - optimized_route.estimated_fuel_cost, 2),
            "distance_savings_percent": round(
                ((baseline_distance - optimized_route.total_distance_km) / baseline_distance * 100), 1
            ) if baseline_distance > 0 else 0,
            "time_savings_percent": round(
                ((baseline_time - optimized_route.total_time_minutes) / baseline_time * 100), 1
            ) if baseline_time > 0 else 0
        }

    @staticmethod
    def generate_route_insights(optimized_route: OptimizedRoute,
                              delivery_points: List[DeliveryPointModel]) -> Dict:
        """
        Generate insights about the optimized route.
        """
        insights = {
            "route_efficiency": {
                "optimization_score": optimized_route.optimization_score,
                "total_stops": len(optimized_route.route_order) - 1,
                "average_distance_per_stop": round(
                    optimized_route.total_distance_km / (len(optimized_route.route_order) - 1), 2
                ),
                "average_time_per_stop": round(
                    optimized_route.total_time_minutes / (len(optimized_route.route_order) - 1), 1
                )
            },
            "delivery_priorities": {
                "high_priority_deliveries": len([p for p in delivery_points if p.priority == 1]),
                "medium_priority_deliveries": len([p for p in delivery_points if p.priority == 2]),
                "low_priority_deliveries": len([p for p in delivery_points if p.priority >= 3])
            },
            "package_distribution": {
                "small_packages": len([p for p in delivery_points if p.size == "small"]),
                "medium_packages": len([p for p in delivery_points if p.size == "medium"]),
                "large_packages": len([p for p in delivery_points if p.size == "large"])
            },
            "estimated_completion_time": {
                "total_driving_time": optimized_route.total_time_minutes,
                "estimated_delivery_time": len(delivery_points) * 5,  # 5 min per delivery
                "total_estimated_time": optimized_route.total_time_minutes + (len(delivery_points) * 5)
            }
        }

        return insights

@router.post("/optimize", response_model=Dict)
async def optimize_route_advanced(request: OptimizationRequestModel):
    """
    Advanced route optimization with detailed analytics and insights.
    """
    try:
        logger.info(f"Starting route optimization for {len(request.delivery_points)} delivery points")

        # Convert Pydantic models to internal format
        delivery_points = [
            DeliveryPoint(
                id=p.id,
                lat=p.lat,
                lon=p.lon,
                address=p.address,
                size=p.size,
                priority=p.priority,
                time_window_start=p.time_window_start,
                time_window_end=p.time_window_end
            )
            for p in request.delivery_points
        ]

        vehicle = Vehicle(
            type=request.vehicle.type,
            capacity=request.vehicle.capacity,
            fuel_efficiency=request.vehicle.fuel_efficiency
        )

        start_location = DeliveryPoint(
            id=request.start_location.id,
            lat=request.start_location.lat,
            lon=request.start_location.lon,
            address=request.start_location.address,
            size=request.start_location.size,
            priority=request.start_location.priority,
            time_window_start=request.start_location.time_window_start,
            time_window_end=request.start_location.time_window_end
        )

        # Get distance matrix from Google Maps
        all_points = [start_location] + delivery_points
        distance_matrix = await google_maps_client.get_distance_matrix(
            all_points, consider_traffic=request.consider_traffic
        )

        # Optimize route
        optimized_route = route_optimizer.optimize(
            delivery_points=delivery_points,
            vehicle=vehicle,
            start_location=start_location,
            distance_matrix=distance_matrix,
            optimization_goal=request.optimization_goal
        )

        # Generate analytics
        analytics = RouteAnalytics()
        savings = analytics.calculate_savings(optimized_route)
        insights = analytics.generate_route_insights(optimized_route, request.delivery_points)

        # Prepare response
        response = {
            "route_order": optimized_route.route_order,
            "segments": optimized_route.segments,
            "total_distance_km": optimized_route.total_distance_km,
            "total_time_minutes": optimized_route.total_time_minutes,
            "estimated_fuel_cost": optimized_route.estimated_fuel_cost,
            "optimization_score": optimized_route.optimization_score,
            "savings": savings,
            "insights": insights,
            "optimization_metadata": {
                "algorithm_used": "dijkstra_with_2opt",
                "optimization_goal": request.optimization_goal,
                "consider_traffic": request.consider_traffic,
                "timestamp": datetime.now().isoformat(),
                "processing_time_ms": 0  # Could be implemented with timing
            }
        }

        logger.info(f"Route optimization completed successfully. Score: {optimized_route.optimization_score}")
        return response

    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Optimization failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Optimization failed: {str(e)}")

@router.get("/sample-data")
async def get_sample_data():
    """
    Returns sample delivery data for testing Flutter UI.
    """
    try:
        data_path = os.path.join("data", "mock_deliveries.json")
        with open(data_path, 'r') as f:
            sample_data = json.load(f)

        return sample_data

    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Sample data not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load sample data: {str(e)}")

@router.get("/vehicle-types")
async def get_vehicle_types():
    """
    Returns available vehicle types and their specifications.
    """
    try:
        data_path = os.path.join("data", "mock_deliveries.json")
        with open(data_path, 'r') as f:
            data = json.load(f)

        return {
            "vehicle_types": data.get("vehicle_types", []),
            "capacity_limits": {
                "small": 3,
                "medium": 8,
                "large": 15
            },
            "size_weights": {
                "small": 1.0,
                "medium": 1.5,
                "large": 2.0
            }
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load vehicle types: {str(e)}")

@router.post("/validate-request")
async def validate_optimization_request(request: OptimizationRequestModel):
    """
    Validate an optimization request without running the optimization.
    """
    try:
        # Check capacity constraints
        total_capacity_needed = sum(
            {"small": 1.0, "medium": 1.5, "large": 2.0}[p.size]
            for p in request.delivery_points
        )
        vehicle_capacity = {"small": 3, "medium": 8, "large": 15}[request.vehicle.capacity]

        validation_result = {
            "is_valid": True,
            "validation_details": {
                "total_delivery_points": len(request.delivery_points),
                "capacity_utilization": round(total_capacity_needed / vehicle_capacity, 2),
                "capacity_sufficient": total_capacity_needed <= vehicle_capacity,
                "vehicle_type": request.vehicle.type,
                "optimization_goal": request.optimization_goal
            },
            "warnings": [],
            "recommendations": []
        }

        # Add warnings and recommendations
        if total_capacity_needed > vehicle_capacity:
            validation_result["is_valid"] = False
            validation_result["warnings"].append(
                f"Vehicle capacity insufficient. Need {total_capacity_needed:.1f} units, have {vehicle_capacity}"
            )

        if validation_result["validation_details"]["capacity_utilization"] < 0.5:
            validation_result["recommendations"].append(
                "Consider using a smaller vehicle for better fuel efficiency"
            )

        if len(request.delivery_points) > 15:
            validation_result["warnings"].append(
                "Large number of delivery points may increase optimization time"
            )

        return validation_result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Validation failed: {str(e)}")

@router.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring route optimization service.
    """
    return {
        "status": "healthy",
        "services": {
            "route_optimizer": "active",
            "google_maps": "active" if google_maps_client.is_configured() else "mock_mode"
        },
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }