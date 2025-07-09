import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fuelEfficiencyController = TextEditingController();
  
  String _selectedVehicleType = 'van';
  String _selectedOptimizationGoal = 'time';
  String _selectedStartLocation = 'Warehouse A';
  bool _considerTraffic = true;
  bool _isLoading = false;

  // Mock data for start locations
  final List<StartLocation> _startLocations = [
    StartLocation(address: 'Warehouse A', lat: 28.6139, lon: 77.2090),
    StartLocation(address: 'Warehouse B', lat: 28.7041, lon: 77.1025),
    StartLocation(address: 'Distribution Center', lat: 28.5355, lon: 77.3910),
  ];

  // Mock delivery points
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
    DeliveryPoint(
      id: 'dp3',
      address: 'Red Fort, New Delhi',
      lat: 28.6562,
      lon: 77.2410,
      size: 'large',
      priority: 'high',
    ),
    DeliveryPoint(
      id: 'dp4',
      address: 'Lotus Temple, New Delhi',
      lat: 28.5535,
      lon: 77.2588,
      size: 'medium',
      priority: 'low',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fuelEfficiencyController.text = '14.0';
  }

  @override
  void dispose() {
    _fuelEfficiencyController.dispose();
    super.dispose();
  }

  Future<void> _optimizeRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final startLocation = _startLocations.firstWhere(
        (location) => location.address == _selectedStartLocation,
      );

      final request = OptimizationRequest(
        deliveryPoints: _deliveryPoints,
        vehicle: Vehicle(
          type: _selectedVehicleType,
          capacity: _getVehicleCapacity(_selectedVehicleType),
          fuelEfficiency: double.parse(_fuelEfficiencyController.text),
        ),
        startLocation: startLocation,
        considerTraffic: _considerTraffic,
        optimizationGoal: _selectedOptimizationGoal,
      );

      // Replace with your actual IP address
      const String baseUrl = 'http://172.31.96.1:8000'; // Change this to your local IP
      final response = await http.post(
        Uri.parse('$baseUrl/optimize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final result = OptimizationResult.fromJson(jsonDecode(response.body));
        
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
        _showErrorDialog('Failed to optimize route: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getVehicleCapacity(String vehicleType) {
    switch (vehicleType) {
      case 'van':
        return 'medium';
      case 'truck':
        return 'large';
      case 'motorcycle':
        return 'small';
      default:
        return 'medium';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RouteGenie'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['van', 'truck', 'motorcycle']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleType = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _fuelEfficiencyController,
                        decoration: InputDecoration(
                          labelText: 'Fuel Efficiency (km/L)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter fuel efficiency';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Location',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStartLocation,
                        decoration: InputDecoration(
                          labelText: 'Select Start Location',
                          border: OutlineInputBorder(),
                        ),
                        items: _startLocations
                            .map((location) => DropdownMenuItem(
                                  value: location.address,
                                  child: Text(location.address),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStartLocation = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Points',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      ..._deliveryPoints.map((point) => Card(
                            elevation: 1,
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(point.address),
                              subtitle: Text(
                                'Size: ${point.size.toUpperCase()} | Priority: ${point.priority.toUpperCase()}',
                              ),
                              trailing: Icon(Icons.location_on),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimization Settings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      Text('Optimization Goal:'),
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: Text('Time'),
                            value: 'time',
                            groupValue: _selectedOptimizationGoal,
                            onChanged: (value) {
                              setState(() {
                                _selectedOptimizationGoal = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: Text('Distance'),
                            value: 'distance',
                            groupValue: _selectedOptimizationGoal,
                            onChanged: (value) {
                              setState(() {
                                _selectedOptimizationGoal = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: Text('Fuel'),
                            value: 'fuel',
                            groupValue: _selectedOptimizationGoal,
                            onChanged: (value) {
                              setState(() {
                                _selectedOptimizationGoal = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      SwitchListTile(
                        title: Text('Consider Traffic'),
                        value: _considerTraffic,
                        onChanged: (value) {
                          setState(() {
                            _considerTraffic = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _optimizeRoute,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(
                        'Optimize Route',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}