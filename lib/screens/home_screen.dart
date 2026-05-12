import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(Position) onPositionFetched; // Callback property
  const HomeScreen({super.key, required this.onPositionFetched});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _latitude = "0.0";
  String _longitude = "0.0";
  String _altitude = "0.0";
  String _temperature = "--";
  bool _isLoading = true;
  Future<void> _refreshData() async {
    try {
      // 1. Fetching position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check if the widget is still in the tree before proceeding
      if (!mounted) return;

      // 2. Notify the parent
      widget.onPositionFetched(position);

      // 3. Fetching weather
      final weatherData = await WeatherService().fetchWeather(
          position.latitude,
          position.longitude
      );

      // 4. Update UI only if the widget is still visible (mounted)
      if (mounted) {
        setState(() {
          _latitude = position.latitude.toString();
          _longitude = position.longitude.toString();
          _altitude = "${position.altitude.toStringAsFixed(1)} m";
          _temperature = "${weatherData['current_weather']['temperature']}°C";
          _isLoading = false;
        });
      }
    } catch (e) {
      // Also check here before updating the loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    // Start fetching data when the widget is first created
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏠 Home")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // GPS Information Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.satellite_alt),
                title: const Text("GPS"),
                subtitle: Text("Latitude: $_latitude\nLongitude: $_longitude\nAltitude: $_altitude"),
              ),
            ),
            const SizedBox(height: 10),
            // Weather Information Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud),
                title: const Text("Current Weather"),
                subtitle: Text("Temperature: $_temperature"),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData, // Allow manual refresh
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}