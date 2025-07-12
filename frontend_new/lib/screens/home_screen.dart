import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models.dart';
import 'result_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = dotenv.env['BASE_URL'] ?? '';
final String apiKey = dotenv.env['API_KEY'] ?? '';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fuelEfficiencyController = TextEditingController(text: '14.0');

  String _selectedVehicleType = 'van';
  String _selectedOptimizationGoal = 'time';
  String _selectedStartLocation = 'Warehouse A';
  bool _considerTraffic = true;
  bool _isLoading = false;

  final List<DeliveryPoint> _startLocations = [
    DeliveryPoint(
      id: 'start1',
      address: 'Warehouse A',
      lat: 28.6139,
      lon: 77.2090,
      size: 'medium',
      priority: 'medium',
    ),
    DeliveryPoint(
      id: 'start2',
      address: 'Warehouse B',
      lat: 28.7041,
      lon: 77.1025,
      size: 'medium',
      priority: 'medium',
    ),
  ];

  final List<DeliveryPoint> _deliveryPoints = [
    DeliveryPoint(
      id: 'dp1',
      address: 'Connaught Place, New Delhi',
      lat: 28.6315,
      lon: 77.2167,
      size: 'medium',
      priority: 'high',
    ),
    DeliveryPoint(
      id: 'dp2',
      address: 'India Gate, New Delhi',
      lat: 28.6129,
      lon: 77.2295,
      size: 'small',
      priority: 'medium',
    ),
  ];

  void _addDeliveryPoint() {
    String address = '';
    double lat = 0, lon = 0;
    String size = 'medium';
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Delivery Point'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  decoration: InputDecoration(labelText: 'Address'),
                  onChanged: (v) => address = v),
              TextField(
                  decoration: InputDecoration(labelText: 'Latitude'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => lat = double.tryParse(v) ?? 0),
              TextField(
                  decoration: InputDecoration(labelText: 'Longitude'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => lon = double.tryParse(v) ?? 0),
              DropdownButton<String>(
                value: size,
                onChanged: (v) => setState(() => size = v!),
                items: ['small', 'medium', 'large']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
              ),
              DropdownButton<String>(
                value: priority,
                onChanged: (v) => setState(() => priority = v!),
                items: ['low', 'medium', 'high']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Add'),
            onPressed: () {
              setState(() {
                _deliveryPoints.add(DeliveryPoint(
                  id: 'dp${_deliveryPoints.length + 1}',
                  address: address,
                  lat: lat,
                  lon: lon,
                  size: size,
                  priority: priority,
                ));
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  Future<void> _optimizeRoute() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final startLocation = _startLocations.firstWhere(
      (s) => s.address == _selectedStartLocation,
    );

    final request = OptimizationRequest(
      deliveryPoints: _deliveryPoints,
      vehicle: Vehicle(
        type: _selectedVehicleType,
        capacity: _getVehicleCapacity(_selectedVehicleType),
        fuelEfficiency: double.tryParse(_fuelEfficiencyController.text) ?? 14.0,
      ),
      startLocation: startLocation,
      considerTraffic: _considerTraffic,
      optimizationGoal: _selectedOptimizationGoal,
    );

    try {
      final requestBody = jsonEncode(request.toJson());
      print('Sending optimization request: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/optimize'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result =
            OptimizationResult.fromJson(jsonDecode(response.body));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              result: result,
              startLocation: startLocation,
              deliveryPoints: _deliveryPoints,
            ),
          ),
        );
      } else {
        _showError('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getVehicleCapacity(String type) {
    if (type == 'truck') return 'large';
    if (type == 'motorcycle') return 'small';
    return 'medium';
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RouteGenie')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      onChanged: (v) =>
                          setState(() => _selectedVehicleType = v!),
                      decoration: InputDecoration(labelText: 'Vehicle Type'),
                      items: ['van', 'truck', 'motorcycle']
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text(v)))
                          .toList(),
                    ),
                    TextFormField(
                      controller: _fuelEfficiencyController,
                      decoration: InputDecoration(
                          labelText: 'Fuel Efficiency (km/L)'),
                      keyboardType: TextInputType.number,
                    )
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: _selectedStartLocation,
                  onChanged: (v) =>
                      setState(() => _selectedStartLocation = v!),
                  decoration: InputDecoration(labelText: 'Start Location'),
                  items: _startLocations
                      .map((s) => DropdownMenuItem(
                          value: s.address, child: Text(s.address)))
                      .toList(),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(title: Text('Delivery Points')),
                    ..._deliveryPoints.map((p) => ListTile(
                          title: Text(p.address),
                          subtitle:
                              Text('Size: ${p.size}, Priority: ${p.priority}'),
                          trailing: Icon(Icons.location_pin),
                        )),
                    ElevatedButton(
                      onPressed: _addDeliveryPoint,
                      child: Text('Add Delivery Point'),
                    )
                  ],
                ),
              ),
            ),
            SwitchListTile(
              title: Text('Consider Traffic'),
              value: _considerTraffic,
              onChanged: (v) => setState(() => _considerTraffic = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['time', 'distance', 'fuel']
                  .map(
                    (goal) => Row(children: [
                      Radio<String>(
                        value: goal,
                        groupValue: _selectedOptimizationGoal,
                        onChanged: (v) =>
                            setState(() => _selectedOptimizationGoal = v!),
                      ),
                      Text(goal),
                    ]),
                  )
                  .toList(),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _optimizeRoute,
              child:
                  _isLoading ? CircularProgressIndicator() : Text('Optimize'),
            )
          ]),
        ),
      ),
    );
  }
}
