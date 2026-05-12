import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/location_point.dart';

class StorageService {
  final String fileName = "locations.csv";

  // Get the local path for the CSV file
  Future<File> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  // SAVE: Exact order [0:Icon, 1:Timestamp, 2:Lat, 3:Lon, 4:Alt]
  Future<void> saveLocation(LocationPoint point) async {
    final file = await _getFilePath();

    List<List<dynamic>> rows = [
      [
        point.source,      // Index 0
        point.timestamp,   // Index 1
        point.latitude,    // Index 2
        point.longitude,   // Index 3
        point.altitude     // Index 4
      ]
    ];

    // Convert to CSV string with semicolon
    String csvRow = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    await file.writeAsString('$csvRow\n', mode: FileMode.append);
  }

  // LOAD: Maps indices 0 to 4 strictly to avoid RangeError
  Future<List<LocationPoint>> loadLocations() async {
    final file = await _getFilePath();
    if (!await file.exists()) return [];

    final contents = await file.readAsString();
    List<List<dynamic>> csvTable = const CsvToListConverter(fieldDelimiter: ';').convert(contents);

    // Safety: only process rows that have exactly 5 columns
    return csvTable.where((row) => row.length >= 5).map((row) {
      return LocationPoint(
        source: row.toString(),
        timestamp: row[2].toString(),
        latitude: double.tryParse(row[3].toString()) ?? 0.0,
        longitude: double.tryParse(row[4].toString()) ?? 0.0,
        altitude: double.tryParse(row[5].toString()) ?? 0.0, // This is Index 4
      );
    }).toList();
  }

  // Completely clear the file
  Future<void> deleteAll() async {
    final file = await _getFilePath();
    if (await file.exists()) {
      await file.writeAsString("");
    }
  }

  // Delete specific point and rewrite
  Future<void> deleteAtIndex(int index) async {
    List<LocationPoint> currentList = await loadLocations();
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      final file = await _getFilePath();
      await file.writeAsString("");
      for (var p in currentList) {
        await saveLocation(p);
      }
    }
  }
}