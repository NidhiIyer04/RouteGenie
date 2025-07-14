import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final totalDeliveries = 24;
    final successful = 22;
    final failed = 2;
    final totalDistance = 42.3; // km
    final totalTime = 195; // minutes
    final fuelCost = 820.0; // INR

    return Scaffold(
      appBar: AppBar(
        title: const Text('RouteGenie Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryCard('Total Deliveries', totalDeliveries.toString()),
                _summaryCard('Success', '$successful/$totalDeliveries'),
                _summaryCard('Failed', failed.toString(), color: Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryCard('Total Distance', '${totalDistance.toStringAsFixed(1)} km'),
                _summaryCard('Total Time', '${(totalTime / 60).toStringAsFixed(1)} hrs'),
                _summaryCard('Fuel Cost', '₹${fuelCost.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 24),
            // Latest routes (dummy list)
            _sectionTitle('Recent Routes'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('#${index + 1}'),
                    ),
                    title: const Text('Route from Warehouse A'),
                    subtitle: const Text('12 deliveries • 15.2 km • 1.5 hrs'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Live drivers dummy section
            _sectionTitle('Live Drivers'),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(4, (index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_shipping, size: 32, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text('Driver ${index + 1}', style: const TextStyle(fontSize: 12)),
                        const Text('Online', style: TextStyle(color: Colors.green, fontSize: 10)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, {Color color = Colors.blue}) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 100,
        height: 80,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
