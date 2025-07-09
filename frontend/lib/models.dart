class StartLocation {
  final String address;
  final double lat;
  final double lon;

  StartLocation({
    required this.address,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'lat': lat,
        'lon': lon,
      };
}

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
        'priority': priority,
      };
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
        'fuelEfficiency': fuelEfficiency,
      };
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

  Map<String, dynamic> toJson() => {
        'deliveryPoints': deliveryPoints.map((dp) => dp.toJson()).toList(),
        'vehicle': vehicle.toJson(),
        'startLocation': startLocation.toJson(),
        'considerTraffic': considerTraffic,
        'optimizationGoal': optimizationGoal,
      };
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
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 0,
      trafficDelayMinutes: json['traffic_delay_minutes'] ?? 0,
    );
  }
}
