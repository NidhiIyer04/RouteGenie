import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late GoogleMapController _mapController;
  Timer? _refreshTimer;

  // Filter controls
  DateTimeRange? _selectedDateRange;
  String? _selectedDriver;
  String? _selectedRegion;

  // Chart selection
  int _selectedChartIndex = -1;

  // Dummy data
  List<Driver> _drivers = [
    Driver(id: '1', name: 'John Smith', lat: 40.7128, lng: -74.0060, status: 'active'),
    Driver(id: '2', name: 'Sarah Johnson', lat: 40.7589, lng: -73.9851, status: 'active'),
    Driver(id: '3', name: 'Mike Davis', lat: 40.7505, lng: -73.9934, status: 'break'),
    Driver(id: '4', name: 'Emma Wilson', lat: 40.7282, lng: -73.7949, status: 'active'),
    Driver(id: '5', name: 'David Brown', lat: 40.6892, lng: -74.0445, status: 'offline'),
  ];

  List<DeliveryRoute> _routes = [
    DeliveryRoute(
      id: '1',
      driver: 'John Smith',
      region: 'Manhattan',
      stops: 8,
      distance: 24.5,
      estimatedTime: 2.5,
      status: 'on-time',
      date: DateTime.now().subtract(Duration(hours: 2)),
      success: true,
    ),
    DeliveryRoute(
      id: '2',
      driver: 'Sarah Johnson',
      region: 'Brooklyn',
      stops: 12,
      distance: 31.2,
      estimatedTime: 3.2,
      status: 'delayed',
      date: DateTime.now().subtract(Duration(hours: 5)),
      success: false,
    ),
    DeliveryRoute(
      id: '3',
      driver: 'Mike Davis',
      region: 'Queens',
      stops: 6,
      distance: 18.3,
      estimatedTime: 1.8,
      status: 'completed',
      date: DateTime.now().subtract(Duration(days: 1)),
      success: true,
    ),
    DeliveryRoute(
      id: '4',
      driver: 'Emma Wilson',
      region: 'Bronx',
      stops: 15,
      distance: 42.1,
      estimatedTime: 4.1,
      status: 'on-time',
      date: DateTime.now().subtract(Duration(days: 2)),
      success: true,
    ),
    DeliveryRoute(
      id: '5',
      driver: 'David Brown',
      region: 'Staten Island',
      stops: 9,
      distance: 27.8,
      estimatedTime: 2.9,
      status: 'completed',
      date: DateTime.now().subtract(Duration(days: 3)),
      success: true,
    ),
  ];

  List<WeeklyDelivery> _weeklyData = [
    WeeklyDelivery(day: 'Mon', deliveries: 45),
    WeeklyDelivery(day: 'Tue', deliveries: 52),
    WeeklyDelivery(day: 'Wed', deliveries: 38),
    WeeklyDelivery(day: 'Thu', deliveries: 61),
    WeeklyDelivery(day: 'Fri', deliveries: 48),
    WeeklyDelivery(day: 'Sat', deliveries: 23),
    WeeklyDelivery(day: 'Sun', deliveries: 19),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _simulateDataUpdate();
    });
  }

  void _simulateDataUpdate() {
    setState(() {
      // Simulate driver position updates
      for (var driver in _drivers) {
        driver.lat += (0.001 * (2 * (0.5 - DateTime.now().millisecond / 1000)));
        driver.lng += (0.001 * (2 * (0.5 - DateTime.now().microsecond / 1000)));
      }
    });
  }

  List<DeliveryRoute> get _filteredRoutes {
    List<DeliveryRoute> filtered = List.from(_routes);

    if (_selectedDateRange != null) {
      filtered = filtered.where((route) =>
          route.date.isAfter(_selectedDateRange!.start) &&
          route.date.isBefore(_selectedDateRange!.end)).toList();
    }

    if (_selectedDriver != null) {
      filtered = filtered.where((route) => route.driver == _selectedDriver).toList();
    }

    if (_selectedRegion != null) {
      filtered = filtered.where((route) => route.region == _selectedRegion).toList();
    }

    if (_selectedChartIndex != -1) {
      bool filterSuccess = _selectedChartIndex == 0;
      filtered = filtered.where((route) => route.success == filterSuccess).toList();
    }

    return filtered;
  }

  void _exportToCsv() {
    List<List<String>> csvData = [
      ['Route ID', 'Driver', 'Region', 'Stops', 'Distance (km)', 'Time (hours)', 'Status', 'Date'],
      ..._filteredRoutes.map((route) => [
        route.id,
        route.driver,
        route.region,
        route.stops.toString(),
        route.distance.toString(),
        route.estimatedTime.toString(),
        route.status,
        route.date.toString(),
      ]).toList(),
    ];

    String csvContent = csvData.map((row) => row.join(',')).join('\n');
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'route_data.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void _uploadCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV uploaded successfully! Ready to process addresses.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('RouteGenie Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Stats Row
            Row(
              children: [
                _buildStatCard('Active Drivers', '${_drivers.where((d) => d.status == 'active').length}', Icons.local_shipping, Colors.green),
                SizedBox(width: 16),
                _buildStatCard('Total Routes', '${_routes.length}', Icons.route, Colors.blue),
                SizedBox(width: 16),
                _buildStatCard('CO₂ Saved', '142 kg', Icons.eco, Colors.green),
                SizedBox(width: 16),
                _buildStatCard('Efficiency', '94%', Icons.trending_up, Colors.orange),
              ],
            ),
            SizedBox(height: 24),

            // Main Content Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Map and Routes
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Live Map
                      Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            initialCameraPosition: CameraPosition(
                              target: LatLng(40.7128, -74.0060),
                              zoom: 11,
                            ),
                            markers: _drivers.map((driver) => Marker(
                              markerId: MarkerId(driver.id),
                              position: LatLng(driver.lat, driver.lng),
                              infoWindow: InfoWindow(
                                title: driver.name,
                                snippet: 'Status: ${driver.status}',
                              ),
                              icon: driver.status == 'active'
                                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                                : driver.status == 'break'
                                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow)
                                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            )).toSet(),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Recent Routes
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Recent Routes',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              height: 300,
                              child: ListView.builder(
                                itemCount: _filteredRoutes.length,
                                itemBuilder: (context, index) {
                                  final route = _filteredRoutes[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(route.status),
                                      child: Text(route.stops.toString()),
                                    ),
                                    title: Text('${route.driver} - ${route.region}'),
                                    subtitle: Text('${route.distance} km • ${route.estimatedTime}h'),
                                    trailing: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(route.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        route.status,
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 24),

                // Right Column - Filters and Charts
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Filters & Controls
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Filters & Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),

                            // Date Range Picker
                            OutlinedButton.icon(
                              onPressed: () async {
                                DateTimeRange? picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime.now().subtract(Duration(days: 30)),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDateRange = picked;
                                  });
                                }
                              },
                              icon: Icon(Icons.date_range),
                              label: Text(_selectedDateRange == null ? 'Select Date Range' : 'Date Range Set'),
                            ),
                            SizedBox(height: 12),

                            // Driver Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedDriver,
                              decoration: InputDecoration(
                                labelText: 'Driver',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(value: null, child: Text('All Drivers')),
                                ..._drivers.map((driver) => DropdownMenuItem(
                                  value: driver.name,
                                  child: Text(driver.name),
                                )).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDriver = value;
                                });
                              },
                            ),
                            SizedBox(height: 12),

                            // Region Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedRegion,
                              decoration: InputDecoration(
                                labelText: 'Region',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(value: null, child: Text('All Regions')),
                                DropdownMenuItem(value: 'Manhattan', child: Text('Manhattan')),
                                DropdownMenuItem(value: 'Brooklyn', child: Text('Brooklyn')),
                                DropdownMenuItem(value: 'Queens', child: Text('Queens')),
                                DropdownMenuItem(value: 'Bronx', child: Text('Bronx')),
                                DropdownMenuItem(value: 'Staten Island', child: Text('Staten Island')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRegion = value;
                                });
                              },
                            ),
                            SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _exportToCsv,
                                    icon: Icon(Icons.download),
                                    label: Text('Export CSV'),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _uploadCsv,
                                    icon: Icon(Icons.upload),
                                    label: Text('Upload CSV'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Success Rate Pie Chart
                      Container(
                        height: 300,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery Success Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    PieChartSectionData(
                                      color: Colors.green,
                                      value: _routes.where((r) => r.success).length.toDouble(),
                                      title: 'Success\n${(_routes.where((r) => r.success).length / _routes.length * 100).toStringAsFixed(1)}%',
                                      radius: _selectedChartIndex == 0 ? 60 : 50,
                                      titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      color: Colors.red,
                                      value: _routes.where((r) => !r.success).length.toDouble(),
                                      title: 'Failed\n${(_routes.where((r) => !r.success).length / _routes.length * 100).toStringAsFixed(1)}%',
                                      radius: _selectedChartIndex == 1 ? 60 : 50,
                                      titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                          _selectedChartIndex = -1;
                                          return;
                                        }
                                        _selectedChartIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Weekly Deliveries Bar Chart
                      Container(
                        height: 300,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weekly Deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),
                            Expanded(
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 70,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text(_weeklyData[value.toInt()].day);
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _weeklyData.asMap().entries.map((entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value.deliveries.toDouble(),
                                          color: Colors.blue,
                                          width: 16,
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Icon(icon, color: color),
              ],
            ),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'on-time':
        return Colors.green;
      case 'delayed':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class Driver {
  final String id;
  final String name;
  double lat;
  double lng;
  final String status;

  Driver({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.status,
  });
}

class DeliveryRoute {
  final String id;
  final String driver;
  final String region;
  final int stops;
  final double distance;
  final double estimatedTime;
  final String status;
  final DateTime date;
  final bool success;

  DeliveryRoute({
    required this.id,
    required this.driver,
    required this.region,
    required this.stops,
    required this.distance,
    required this.estimatedTime,
    required this.status,
    required this.date,
    required this.success,
  });
}

class WeeklyDelivery {
  final String day;
  final int deliveries;

  WeeklyDelivery({required this.day, required this.deliveries});
}