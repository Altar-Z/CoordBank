import 'dart:convert';
import '../models/location_point.dart';

class SharingService {
  // Transforme un point en code (ex: "MzczLjQyOy0xMjIuMDg...")
  static String generateCode(LocationPoint point) {
    // On concatène les infos essentielles séparées par un caractère spécial
    String safeNote = point.userNote.replaceAll(';', ',');
    String rawData = "${point.latitude};${point.longitude};${point.altitude};${point.timestamp};$safeNote";
    // On encode en Base64 pour donner l'aspect d'un "code"
    return base64Encode(utf8.encode(rawData));
  }

  // Transforme un code reçu en objet LocationPoint
  static LocationPoint? decodeCode(String code) {
    try {
      String decodedRaw = utf8.decode(base64Decode(code));
      List<String> parts = decodedRaw.split(';');
      if (parts.length >= 5) {
        return LocationPoint(
          latitude: double.parse(parts[0]),
          longitude: double.parse(parts[1]),
          altitude: double.parse(parts[2]),
          timestamp: parts[3],
          userNote: parts[4],
          source: "🎁", // Nouvel émoji pour les points reçus
        );
      }
    } catch (e) {
      return null; // Code invalide
    }
    return null;
  }
}