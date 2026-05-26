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
  Future<List<LocationPoint>> loadLocations() async {
    final file = await _getFilePath();
    if (!await file.exists()) return [];

    // On utilise readAsLines() pour forcer la séparation des lignes [1]
    List<String> lines = await file.readAsLines();

    // On transforme chaque ligne de texte en un objet LocationPoint
    return lines.where((line) => line.isNotEmpty).map((line) {
      // On découpe la ligne par le point-virgule [1]
      List<String> columns = line.split(';');

      // Sécurité : on vérifie qu'on a bien nos 5 colonnes
      if (columns.length >= 5) {
        return LocationPoint(
          source: columns[0],      // Cible l'index 0 pour l'émoji [1]
          timestamp: columns[1],   // Cible l'index 1 pour la date
          latitude: double.tryParse(columns[2]) ?? 0.0,
          longitude: double.tryParse(columns[3]) ?? 0.0,
          altitude: double.tryParse(columns[4]) ?? 0.0,
        );
      }
      return null;
    })
        .whereType<LocationPoint>() // Enlève les lignes mal formées
        .toList();
  }
/*
  // LOAD: Maps indices 0 to 4 strictly to avoid RangeError
  Future<List<LocationPoint>> loadLocations() async {
    final file = await _getFilePath();
    if (!await file.exists()) return [];

    final contents = await file.readAsLines();
    List<String> Lines = const CsvToListConverter(fieldDelimiter: ';').convert(contents);
    print(csvTable);
    // Safety: only process rows that have exactly 5 columns
    return csvTable.where((row) => row.length >= 5).map((row) {
      return LocationPoint(
        source: row[0].toString(),
        timestamp: row[1].toString(),
        latitude: double.tryParse(row[2].toString()) ?? 0.0,
        longitude: double.tryParse(row[3].toString()) ?? 0.0,
        altitude: double.tryParse(row[4].toString()) ?? 619.93654, // This is Index 4
      );
    }).toList();
  }
*/
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