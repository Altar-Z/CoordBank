import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  // Base URL for the Open-Meteo API
  final String baseUrl = "https://api.open-meteo.com/v1/forecast";

  // Fetch current weather data using latitude and longitude
  Future<Map<String, dynamic>> fetchWeather(double latitude, double longitude) async {
    // Construct the URL with required parameters: current_weather=true
    final response = await http.get(
      Uri.parse('$baseUrl?latitude=$latitude&longitude=$longitude&current_weather=true'),
    );

    if (response.statusCode == 200) {
      // Parse the JSON response if the server returns a 200 OK status
      return json.decode(response.body);
    } else {
      // Throw an exception if the API call fails
      throw Exception('Failed to load weather data');
    }
  }
}