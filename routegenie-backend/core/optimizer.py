import heapq
import math
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
import json

@dataclass
class DeliveryPoint:
    id: str
    lat: float
    lon: float
    address: str
    size: str
    priority: int
    time_window_start: Optional[str] = None
    time_window_end: Optional[str] = None

@dataclass
class Vehicle:
    type: str
    capacity: str
    fuel_efficiency: float

@dataclass
class RouteSegment:
    from_point: str
    to_point: str
    distance_km: float
    duration_minutes: int
    traffic_delay_minutes: int = 0

@dataclass
class OptimizedRoute:
    route_order: List[str]
    segments: List[RouteSegment]
    total_distance_km: float
    total_time_minutes: int
    estimated_fuel_cost: float
    optimization_score: float

class RouteOptimizer:
    def __init__(self):
        self.fuel_price_per_liter = 105.0  # INR per liter (approximate)
        self.size_weights = {
            "small": 1.0,
            "medium": 1.5,
            "large": 2.0
        }
        self.capacity_limits = {
            "small": 3,
            "medium": 8,
            "large": 15
        }
        self.vehicle_speed_kmh = {
            "motorcycle": 25,
            "van": 20,
            "truck": 15
        }

    def calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculate the Haversine distance between two points on Earth.
        Returns distance in kilometers.
        """
        R = 6371  # Earth's radius in kilometers

        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)

        a = (math.sin(delta_lat / 2) ** 2 +
             math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

    def build_distance_matrix(self, points: List[DeliveryPoint],
                            external_matrix: Optional[Dict] = None) -> Dict[str, Dict[str, Dict]]:
        """
        Build a distance matrix between all points.
        Uses external matrix if provided, otherwise calculates Haversine distances.
        """
        matrix = {}

        for i, point1 in enumerate(points):
            matrix[point1.id] = {}
            for j, point2 in enumerate(points):
                if i == j:
                    matrix[point1.id][point2.id] = {
                        "distance_km": 0.0,
                        "duration_minutes": 0,
                        "traffic_delay_minutes": 0
                    }
                else:
                    # Use external matrix if available
                    if external_matrix and point1.id in external_matrix and point2.id in external_matrix[point1.id]:
                        matrix[point1.id][point2.id] = external_matrix[point1.id][point2.id]
                    else:
                        # Calculate Haversine distance
                        distance = self.calculate_distance(
                            point1.lat, point1.lon, point2.lat, point2.lon
                        )
                        # Estimate duration based on vehicle type (default to van)
                        duration = (distance / 20) * 60  # 20 km/h average speed
                        matrix[point1.id][point2.id] = {
                            "distance_km": distance,
                            "duration_minutes": int(duration),
                            "traffic_delay_minutes": int(duration * 0.2)  # 20% traffic delay
                        }

        return matrix

    def calculate_route_cost(self, route: List[str], distance_matrix: Dict,
                           vehicle: Vehicle, optimization_goal: str) -> float:
        """
        Calculate the total cost of a route based on optimization goal.
        """
        total_distance = 0.0
        total_time = 0
        total_fuel_cost = 0.0

        for i in range(len(route) - 1):
            from_point = route[i]
            to_point = route[i + 1]

            segment_data = distance_matrix[from_point][to_point]
            total_distance += segment_data["distance_km"]
            total_time += segment_data["duration_minutes"] + segment_data["traffic_delay_minutes"]

        # Calculate fuel cost
        total_fuel_cost = (total_distance / vehicle.fuel_efficiency) * self.fuel_price_per_liter

        # Return cost based on optimization goal
        if optimization_goal == "distance":
            return total_distance
        elif optimization_goal == "fuel":
            return total_fuel_cost
        else:  # time
            return total_time

    def apply_priority_weights(self, points: List[DeliveryPoint]) -> List[DeliveryPoint]:
        """
        Sort delivery points by priority (1 = highest priority).
        """
        return sorted(points, key=lambda p: p.priority)

    def check_capacity_constraints(self, points: List[DeliveryPoint], vehicle: Vehicle) -> bool:
        """
        Check if the vehicle can handle all delivery points based on capacity.
        """
        total_capacity_needed = sum(self.size_weights[p.size] for p in points)
        vehicle_capacity = self.capacity_limits[vehicle.capacity]

        return total_capacity_needed <= vehicle_capacity

    def nearest_neighbor_tsp(self, points: List[DeliveryPoint], start_point: DeliveryPoint,
                           distance_matrix: Dict, vehicle: Vehicle, optimization_goal: str) -> List[str]:
        """
        Solve TSP using nearest neighbor heuristic.
        """
        all_points = [start_point] + points
        unvisited = set(p.id for p in points)
        route = [start_point.id]
        current = start_point.id

        while unvisited:
            nearest = None
            min_cost = float('inf')

            for point_id in unvisited:
                cost = distance_matrix[current][point_id]["distance_km"]
                if optimization_goal == "time":
                    cost = (distance_matrix[current][point_id]["duration_minutes"] +
                           distance_matrix[current][point_id]["traffic_delay_minutes"])
                elif optimization_goal == "fuel":
                    cost = (distance_matrix[current][point_id]["distance_km"] /
                           vehicle.fuel_efficiency) * self.fuel_price_per_liter

                if cost < min_cost:
                    min_cost = cost
                    nearest = point_id

            route.append(nearest)
            unvisited.remove(nearest)
            current = nearest

        return route

    def dijkstra_shortest_path(self, points: List[DeliveryPoint], start_point: DeliveryPoint,
                             distance_matrix: Dict, vehicle: Vehicle, optimization_goal: str) -> List[str]:
        """
        Use Dijkstra's algorithm to find optimal route.
        Modified for TSP-like problem with priority considerations.
        """
        # For simplicity, use nearest neighbor with priority weighting
        # In production, implement proper Dijkstra for TSP or use more sophisticated algorithms

        # Apply priority sorting first
        sorted_points = self.apply_priority_weights(points)

        # Use nearest neighbor on priority-sorted points
        return self.nearest_neighbor_tsp(sorted_points, start_point, distance_matrix, vehicle, optimization_goal)

    def two_opt_improvement(self, route: List[str], distance_matrix: Dict,
                          vehicle: Vehicle, optimization_goal: str) -> List[str]:
        """
        Apply 2-opt improvement to the route.
        """
        best_route = route.copy()
        best_cost = self.calculate_route_cost(best_route, distance_matrix, vehicle, optimization_goal)
        improved = True

        while improved:
            improved = False
            for i in range(1, len(route) - 2):
                for j in range(i + 1, len(route)):
                    if j - i == 1:
                        continue

                    # Create new route by reversing segment between i and j
                    new_route = route[:i] + route[i:j][::-1] + route[j:]
                    new_cost = self.calculate_route_cost(new_route, distance_matrix, vehicle, optimization_goal)

                    if new_cost < best_cost:
                        best_route = new_route
                        best_cost = new_cost
                        improved = True
                        break

                if improved:
                    break

            route = best_route

        return best_route

    def build_route_segments(self, route: List[str], distance_matrix: Dict) -> List[RouteSegment]:
        """
        Build detailed route segments from the optimized route.
        """
        segments = []

        for i in range(len(route) - 1):
            from_point = route[i]
            to_point = route[i + 1]

            segment_data = distance_matrix[from_point][to_point]
            segment = RouteSegment(
                from_point=from_point,
                to_point=to_point,
                distance_km=segment_data["distance_km"],
                duration_minutes=segment_data["duration_minutes"],
                traffic_delay_minutes=segment_data["traffic_delay_minutes"]
            )
            segments.append(segment)

        return segments

    def calculate_optimization_score(self, route: List[str], distance_matrix: Dict,
                                   vehicle: Vehicle, points: List[DeliveryPoint]) -> float:
        """
        Calculate a confidence score for the optimization (0-1).
        Based on factors like route efficiency, priority adherence, capacity utilization.
        """
        # Calculate route efficiency compared to direct distances
        total_route_distance = sum(
            distance_matrix[route[i]][route[i + 1]]["distance_km"]
            for i in range(len(route) - 1)
        )

        # Calculate theoretical minimum (sum of distances from start to each point)
        start_point = route[0]
        theoretical_min = sum(
            distance_matrix[start_point][point_id]["distance_km"]
            for point_id in route[1:]
        )

        # Efficiency score (lower is better, so invert)
        efficiency_score = theoretical_min / total_route_distance if total_route_distance > 0 else 0

        # Priority adherence score
        priority_score = self.calculate_priority_adherence(route, points)

        # Capacity utilization score
        capacity_score = self.calculate_capacity_utilization(points, vehicle)

        # Combined score (weighted average)
        overall_score = (
            efficiency_score * 0.4 +
            priority_score * 0.3 +
            capacity_score * 0.3
        )

        return min(overall_score, 1.0)

    def calculate_priority_adherence(self, route: List[str], points: List[DeliveryPoint]) -> float:
        """
        Calculate how well the route adheres to delivery priorities.
        """
        point_priorities = {p.id: p.priority for p in points}

        # Check if higher priority items (lower numbers) come first
        priority_violations = 0
        total_comparisons = 0

        for i in range(1, len(route) - 1):
            for j in range(i + 1, len(route)):
                if route[i] in point_priorities and route[j] in point_priorities:
                    total_comparisons += 1
                    if point_priorities[route[i]] > point_priorities[route[j]]:
                        priority_violations += 1

        if total_comparisons == 0:
            return 1.0

        return 1.0 - (priority_violations / total_comparisons)

    def calculate_capacity_utilization(self, points: List[DeliveryPoint], vehicle: Vehicle) -> float:
        """
        Calculate how efficiently the vehicle capacity is utilized.
        """
        total_capacity_needed = sum(self.size_weights[p.size] for p in points)
        vehicle_capacity = self.capacity_limits[vehicle.capacity]

        utilization = total_capacity_needed / vehicle_capacity

        # Optimal utilization is around 80-90%
        if utilization <= 0.9:
            return utilization / 0.9
        else:
            return max(0.1, 1.0 - (utilization - 0.9) * 2)

    def optimize(self, delivery_points: List[DeliveryPoint], vehicle: Vehicle,
                start_location: DeliveryPoint, distance_matrix: Dict,
                optimization_goal: str = "time") -> OptimizedRoute:
        """
        Main optimization method that orchestrates the route optimization process.
        """
        # Convert to internal format if needed
        if isinstance(delivery_points[0], dict):
            delivery_points = [
                DeliveryPoint(
                    id=p["id"],
                    lat=p["lat"],
                    lon=p["lon"],
                    address=p["address"],
                    size=p["size"],
                    priority=p["priority"],
                    time_window_start=p.get("time_window_start"),
                    time_window_end=p.get("time_window_end")
                )
                for p in delivery_points
            ]

        if isinstance(start_location, dict):
            start_location = DeliveryPoint(
                id=start_location["id"],
                lat=start_location["lat"],
                lon=start_location["lon"],
                address=start_location["address"],
                size=start_location["size"],
                priority=start_location["priority"],
                time_window_start=start_location.get("time_window_start"),
                time_window_end=start_location.get("time_window_end")
            )

        if isinstance(vehicle, dict):
            vehicle = Vehicle(
                type=vehicle["type"],
                capacity=vehicle["capacity"],
                fuel_efficiency=vehicle["fuel_efficiency"]
            )

        # Check capacity constraints
        if not self.check_capacity_constraints(delivery_points, vehicle):
            raise ValueError("Vehicle capacity insufficient for all deliveries")

        # Build distance matrix if not provided
        all_points = [start_location] + delivery_points
        if not distance_matrix:
            distance_matrix = self.build_distance_matrix(all_points)

        # Find optimal route using Dijkstra-inspired algorithm
        optimal_route = self.dijkstra_shortest_path(
            delivery_points, start_location, distance_matrix, vehicle, optimization_goal
        )

        # Apply 2-opt improvement
        improved_route = self.two_opt_improvement(
            optimal_route, distance_matrix, vehicle, optimization_goal
        )

        # Build route segments
        segments = self.build_route_segments(improved_route, distance_matrix)

        # Calculate totals
        total_distance = sum(segment.distance_km for segment in segments)
        total_time = sum(
            segment.duration_minutes + segment.traffic_delay_minutes
            for segment in segments
        )
        estimated_fuel_cost = (total_distance / vehicle.fuel_efficiency) * self.fuel_price_per_liter

        # Calculate optimization score
        optimization_score = self.calculate_optimization_score(
            improved_route, distance_matrix, vehicle, delivery_points
        )

        # Convert segments to dict format for JSON serialization
        segments_dict = [
            {
                "from_point": segment.from_point,
                "to_point": segment.to_point,
                "distance_km": segment.distance_km,
                "duration_minutes": segment.duration_minutes,
                "traffic_delay_minutes": segment.traffic_delay_minutes
            }
            for segment in segments
        ]

        return OptimizedRoute(
            route_order=improved_route,
            segments=segments_dict,
            total_distance_km=round(total_distance, 2),
            total_time_minutes=int(total_time),
            estimated_fuel_cost=round(estimated_fuel_cost, 2),
            optimization_score=round(optimization_score, 3)
        )