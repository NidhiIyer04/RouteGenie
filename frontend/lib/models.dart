class StartLocation {
  final String address;
  final double lat;
  final double lon;

  StartLocation({
    required this.address,
    required this.lat,
    required this.lon,
  });
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
        'deliveryPoints': deliveryPoints.map((dp) => {
              'id': dp.id,
              'address': dp.address,
              'lat': dp.lat,
              'lon': dp.lon,
              'size': dp.size,
              'priority': dp.priority,
            }).toList(),
        'vehicle': vehicle.toJson(),
        'startLocation': {
          'address': startLocation.address,
          'lat': startLocation.lat,
          'lon': startLocation.lon,
        },
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
