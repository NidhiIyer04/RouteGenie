import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models.dart';

class ResultScreen extends StatefulWidget {
  final OptimizationResult result;
  final DeliveryPoint startLocation;
  final List<DeliveryPoint> deliveryPoints;

  const ResultScreen({
    Key? key,
    required this.result,
    required this.startLocation,
    required this.deliveryPoints,
  }) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _setPolylines();
  }

  void _setMarkers() {
    final markers = <Marker>{};

    markers.add(Marker(
      markerId: MarkerId('start'),
      position: LatLng(widget.startLocation.lat, widget.startLocation.lon),
      infoWindow: InfoWindow(title: 'Start: ${widget.startLocation.address}'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    for (final point in widget.deliveryPoints) {
      final orderIndex = widget.result.routeOrder.indexOf(point.id);
      final isLast = orderIndex == widget.result.routeOrder.length - 1;

      markers.add(Marker(
        markerId: MarkerId(point.id),
        position: LatLng(point.lat, point.lon),
        infoWindow: InfoWindow(title: point.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isLast ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
        ),
      ));
    }

    setState(() {
      _markers = markers;
    });
  }

  void _setPolylines() {
    final routePoints = <LatLng>[];

    routePoints.add(LatLng(widget.startLocation.lat, widget.startLocation.lon));

    for (String pointId in widget.result.routeOrder) {
      final point = widget.deliveryPoints.firstWhere(
        (p) => p.id == pointId,
        orElse: () => DeliveryPoint(
          id: pointId,
          address: 'Unknown',
          lat: 0,
          lon: 0,
          size: 'unknown',
          priority: 'low',
        ),
      );
      routePoints.add(LatLng(point.lat, point.lon));
    }

    setState(() {
      _polylines = {
        Polyline(
          polylineId: PolylineId('route'),
          color: Colors.blue,
          width: 4,
          points: routePoints,
        )
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Optimized Route'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.startLocation.lat, widget.startLocation.lon),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: widget.result.routeOrder.length,
              itemBuilder: (context, index) {
                final pointId = widget.result.routeOrder[index];
                final point = widget.deliveryPoints.firstWhere(
                  (p) => p.id == pointId,
                  orElse: () => DeliveryPoint(
                    id: pointId,
                    address: 'Unknown',
                    lat: 0,
                    lon: 0,
                    size: 'unknown',
                    priority: 'low',
                  ),
                );
                final segment = index < widget.result.segments.length
                    ? widget.result.segments[index]
                    : null;

                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(point.address),
                  subtitle: segment != null
                      ? Text('${segment.distanceKm.toStringAsFixed(1)} km • ${segment.durationMinutes} min')
                      : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('Total Distance: ${widget.result.totalDistanceKm.toStringAsFixed(1)} km'),
                Text('Total Time: ${widget.result.totalTimeMinutes} minutes'),
                Text('Fuel Cost: ₹${widget.result.estimatedFuelCost.toStringAsFixed(0)}'),
                Text('Optimization Score: ${(widget.result.optimizationScore * 100).toInt()}%'),
              ],
            ),
          )
        ],
      ),
    );
  }
}
