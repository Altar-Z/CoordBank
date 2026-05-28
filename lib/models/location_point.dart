class LocationPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final String timestamp;
  final String source; // Emoji distinction: 📍 for GPS, 🗺️ for Map
  String userNote;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
    required this.source,
    this.userNote = "",
  });
}