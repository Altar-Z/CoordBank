import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/location_point.dart';

class MapScreen extends StatefulWidget {
  // On reçoit la position GPS actuelle depuis le MainScreen pour rester synchrone
  final Position? currentPosition;

  const MapScreen({super.key, this.currentPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final StorageService _storage = StorageService();

  // Fonction pour enregistrer le point situé sous la croix centrale
  Future<void> _savePointedLocation() async {
    // On récupère les coordonnées du centre actuel de la caméra
    final center = _mapController.camera.center;
    String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // On crée un nouveau point avec l'emoji 🗺️ pour le différencier du GPS auto
    LocationPoint newPoint = LocationPoint(
      latitude: center.latitude,
      longitude: center.longitude,
      altitude: 0.0, // L'altitude est inconnue pour un pointage manuel sur carte
      timestamp: now,
      source: "🗺️",
    );

    // Sauvegarde via le service existant (mode append respecté)
    await _storage.saveLocation(newPoint);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pointed location saved to Collection!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Position initiale : soit la position GPS actuelle, soit un point par défaut (ex: Madrid)
    LatLng initialCenter = widget.currentPosition != null
        ? LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude)
        : const LatLng(40.4167, -3.7037);

    return Scaffold(
      appBar: AppBar(title: const Text("🗺️ Map (OpenStreetMap)")),
      body: Stack(
        children: [
          // 1. La Carte (Couche de base)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dart_project',
              ),
              // On affiche un marqueur bleu à la position GPS réelle de l'utilisateur
              if (widget.currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  ],
                ),
            ],
          ),

          // 2. La Croix de visée (Fixe au centre de l'écran)
          const Center(
            child: Icon(
              Icons.add, // Croix simple
              size: 40,
              color: Colors.red,
            ),
          ),

          // 3. Le Bouton de sauvegarde (Positionné en bas)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _savePointedLocation,
                icon: const Icon(Icons.location_on),
                label: const Text("Save pointed location"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}