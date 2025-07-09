class DeliveryPoint {
  final String id;
  final String address;
  final double lat;
  final double lon;
  final String size;
  final String priority;

  DeliveryPoint({
    required this.id,
    required this.address,
    required this.lat,
    required this.lon,
    required this.size,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'lat': lat,
      'lon': lon,
      'size': size,
      'priority': priority,
    };
  }
}

class Vehicle {
  final String type;
  final String capacity;
  final double fuelEfficiency;

  Vehicle({
    required this.type,
    required this.capacity,
    required this.fuelEfficiency,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'capacity': capacity,
      'fuel_efficiency': fuelEfficiency,
    };
  }
}

class StartLocation {
  final String address;
  final double lat;
  final double lon;

  StartLocation({
    required this.address,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'lat': lat,
      'lon': lon,
    };
  }
}

class OptimizationRequest {
  final List<DeliveryPoint> deliveryPoints;
  final Vehicle vehicle;
  final StartLocation startLocation;
  final bool considerTraffic;
  final String optimizationGoal;

  OptimizationRequest({
    required this.deliveryPoints,
    required this.vehicle,
    required this.startLocation,
    required this.considerTraffic,
    required this.optimizationGoal,
  });

  Map<String, dynamic> toJson() {
    return {
      'delivery_points': deliveryPoints.map((dp) => dp.toJson()).toList(),
      'vehicle': vehicle.toJson(),
      'start_location': startLocation.toJson(),
      'consider_traffic': considerTraffic,
      'optimization_goal': optimizationGoal,
    };
  }
}

class RouteSegment {
  final String fromPoint;
  final String toPoint;
  final double distanceKm;
  final int durationMinutes;
  final int trafficDelayMinutes;

  RouteSegment({
    required this.fromPoint,
    required this.toPoint,
    required this.distanceKm,
    required this.durationMinutes,
    required this.trafficDelayMinutes,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      fromPoint: json['from_point'],
      toPoint: json['to_point'],
      distanceKm: json['distance_km'].toDouble(),
      durationMinutes: json['duration_minutes'],
      trafficDelayMinutes: json['traffic_delay_minutes'],
    );
  }
}

class OptimizationResult {
  final List<String> routeOrder;
  final List<RouteSegment> segments;
  final double totalDistanceKm;
  final int totalTimeMinutes;
  final double estimatedFuelCost;
  final double optimizationScore;

  OptimizationResult({
    required this.routeOrder,
    required this.segments,
    required this.totalDistanceKm,
    required this.totalTimeMinutes,
    required this.estimatedFuelCost,
    required this.optimizationScore,
  });

  factory OptimizationResult.fromJson(Map<String, dynamic> json) {
    return OptimizationResult(
      routeOrder: List<String>.from(json['route_order']),
      segments: (json['segments'] as List)
          .map((segment) => RouteSegment.fromJson(segment))
          .toList(),
      totalDistanceKm: json['total_distance_km'].toDouble(),
      totalTimeMinutes: json['total_time_minutes'],
      estimatedFuelCost: json['estimated_fuel_cost'].toDouble(),
      optimizationScore: json['optimization_score'].toDouble(),
    );
  }
}