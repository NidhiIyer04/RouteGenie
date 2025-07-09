import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models.dart';
import 'dart:async';
class ResultScreen extends StatefulWidget {
  final OptimizationResult result;
  final StartLocation startLocation;
  final List<DeliveryPoint> deliveryPoints;

  ResultScreen({
    required this.result,
    required this.startLocation,
    required this.deliveryPoints,
  });

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
    _createMarkers();
    _createPolylines();
  }

  void _createMarkers() {
    // Add start location marker
    _markers.add(
      Marker(
        markerId: MarkerId('start'),
        position: LatLng(widget.startLocation.lat, widget.startLocation.lon),
        infoWindow: InfoWindow(
          title: 'Start Location',
          snippet: widget.startLocation.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Add delivery point markers
    for (int i = 0; i < widget.deliveryPoints.length; i++) {
      final point = widget.deliveryPoints[i];
      final orderIndex = widget.result.routeOrder.indexOf(point.id);
      
      _markers.add(
        Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.lat, point.lon),
          infoWindow: InfoWindow(
            title: 'Stop ${orderIndex + 1}',
            snippet: point.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            orderIndex == widget.result.routeOrder.length - 1
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }
  }

  void _createPolylines() {
    List<LatLng> routePoints = [];
    
    // Add start location
    routePoints.add(LatLng(widget.startLocation.lat, widget.startLocation.lon));
    
    // Add delivery points in optimized order
    for (String pointId in widget.result.routeOrder) {
      final point = widget.deliveryPoints.firstWhere((p) => p.id == pointId);
      routePoints.add(LatLng(point.lat, point.lon));
    }

    _polylines.add(
      Polyline(
        polylineId: PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 4,
        patterns: [],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
          // Route Summary Card
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Summary',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Distance',
                        '${widget.result.totalDistanceKm.toStringAsFixed(1)} km',
                        Icons.straighten,
                      ),
                      _buildSummaryItem(
                        'Time',
                        '${widget.result.totalTimeMinutes} min',
                        Icons.access_time,
                      ),
                      _buildSummaryItem(
                        'Fuel Cost',
                        '₹${widget.result.estimatedFuelCost.toStringAsFixed(0)}',
                        Icons.local_gas_station,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: widget.result.optimizationScore,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.result.optimizationScore > 0.8
                          ? Colors.green
                          : widget.result.optimizationScore > 0.6
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Optimization Score: ${(widget.result.optimizationScore * 100).toInt()}%',
                    style: TextStyle(
                      color: widget.result.optimizationScore > 0.8
                          ? Colors.green
                          : widget.result.optimizationScore > 0.6
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Map
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.startLocation.lat, widget.startLocation.lon),
                  zoom: 11,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          ),
          
          // Delivery Order List
          Expanded(
            flex: 1,
            child: Card(
              margin: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Delivery Order',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.result.routeOrder.length,
                      itemBuilder: (context, index) {
                        final pointId = widget.result.routeOrder[index];
                        final point = widget.deliveryPoints
                            .firstWhere((p) => p.id == pointId);
                        final segment = index < widget.result.segments.length
                            ? widget.result.segments[index]
                            : null;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          title: Text(point.address),
                          subtitle: segment != null
                              ? Text(
                                  '${segment.distanceKm.toStringAsFixed(1)} km • ${segment.durationMinutes} min',
                                )
                              : null,
                          trailing: Icon(
                            Icons.location_on,
                            color: point.priority == 'high'
                                ? Colors.red
                                : point.priority == 'medium'
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}