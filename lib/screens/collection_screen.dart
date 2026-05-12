import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/location_point.dart';
import '../services/storage_service.dart';

class CollectionScreen extends StatefulWidget {
  final Position? currentPosition; // Receive the shared position
  const CollectionScreen({super.key, this.currentPosition});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final StorageService _storage = StorageService();
  List<LocationPoint> _points = [];

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final data = await _storage.loadLocations();
    setState(() => _points = data);
  }

  // ACTION: Save the current position without a new GPS request
  Future<void> _saveStoredLocation() async {
    if (widget.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No location data available from Home page. Please refresh Home first.")),
      );
      return;
    }

    // Prepare data using the already existing coordinates
    String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    LocationPoint newPoint = LocationPoint(
      latitude: widget.currentPosition!.latitude,
      longitude: widget.currentPosition!.longitude,
      altitude: widget.currentPosition!.altitude,
      timestamp: now,
      source: "📍",
    );

    await _storage.saveLocation(newPoint); // Write to CSV [5]
    _loadList(); // Refresh the list view
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📚 Collection")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _saveStoredLocation, // Fast save!
                icon: const Icon(Icons.save),
                label: const Text("Save Home Position"),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _storage.deleteAll();
                  _loadList();
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete All"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _points.length,
              itemBuilder: (context, index) {
                final pt = _points[index];
                return ListTile(
                  leading: SizedBox(width: 40, child:Text(pt.source, style: const TextStyle(fontSize: 24), maxLines: 1, overflow: TextOverflow.ellipsis,),),
                  title: Text("${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)}"),
                  subtitle: Text("Saved on: ${pt.timestamp}\nAlt: ${pt.altitude}m"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _storage.deleteAtIndex(index);
                      _loadList();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}