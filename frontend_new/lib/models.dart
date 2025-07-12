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

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
        'lat': lat,
        'lon': lon,
        'size': size,
        'priority': _priorityToInt(priority),
      };

  int _priorityToInt(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return 1;
      case 'medium':
        return 3;
      case 'low':
        return 5;
      default:
        return 3;
    }
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

  Map<String, dynamic> toJson() => {
        'type': type,
        'capacity': capacity,
        'fuel_efficiency': fuelEfficiency,
      };
}

class OptimizationRequest {
  final List<DeliveryPoint> deliveryPoints;
  final DeliveryPoint startLocation; // match backend's expected model
  final Vehicle vehicle;
  final bool considerTraffic;
  final String optimizationGoal;

  OptimizationRequest({
    required this.deliveryPoints,
    required this.vehicle,
    required this.startLocation,
    required this.considerTraffic,
    required this.optimizationGoal,
  });

  Map<String, dynamic> toJson() => {
        'delivery_points': deliveryPoints.map((dp) => dp.toJson()).toList(),
        'start_location': startLocation.toJson(),
        'vehicle': vehicle.toJson(),
        'consider_traffic': considerTraffic,
        'optimization_goal': optimizationGoal,
      };
}

class RouteSegment {
  final double distanceKm;
  final int durationMinutes;

  RouteSegment({
    required this.distanceKm,
    required this.durationMinutes,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 0,
    );
  }
}

class OptimizationResult {
  final List<String> routeOrder;
  final double totalDistanceKm;
  final int totalTimeMinutes;
  final double estimatedFuelCost;
  final double optimizationScore;
  final List<RouteSegment> segments;

  OptimizationResult({
    required this.routeOrder,
    required this.totalDistanceKm,
    required this.totalTimeMinutes,
    required this.estimatedFuelCost,
    required this.optimizationScore,
    required this.segments,
  });

  factory OptimizationResult.fromJson(Map<String, dynamic> json) {
    return OptimizationResult(
      routeOrder: List<String>.from(json['route_order']),
      totalDistanceKm: (json['total_distance_km'] ?? 0).toDouble(),
      totalTimeMinutes: json['total_time_minutes'] ?? 0,
      estimatedFuelCost: (json['estimated_fuel_cost'] ?? 0).toDouble(),
      optimizationScore: (json['optimization_score'] ?? 0).toDouble(),
      segments: (json['segments'] as List<dynamic>)
          .map((s) => RouteSegment.fromJson(s))
          .toList(),
    );
  }
}
