import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/location_point.dart';
import '../services/storage_service.dart';
import '../services/sharing_service.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
class CollectionScreen extends StatefulWidget {
  final Position? currentPosition; // Receive the shared position
  final Function(LatLng) onSeeOnMap;
  const CollectionScreen({super.key, this.currentPosition, required this.onSeeOnMap});

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
        const SnackBar(content: Text(
            "No location data available from Home page. Please refresh Home first.")),
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
  void _showAddCoordinateDialog(BuildContext context) {
    final TextEditingController _codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter sharing code"),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(hintText: "Paste the code here..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              LocationPoint? receivedPoint = SharingService.decodeCode(_codeController.text);
              if (receivedPoint != null) {
                await _storage.saveLocation(receivedPoint); // Utilise votre service existant [7]
                Navigator.pop(context);
                _loadList(); // Rafraîchit l'écran
              } else {
                // Message d'erreur si le code est mauvais [8]
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid code!")));
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
  void _showShareDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Share this point"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Share this code with your friend:"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey,
                child: SelectableText(
                  code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            // NOUVEAU BOUTON : Copier
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text("Copy"),
              onPressed: () async {
                // Action de copie dans le presse-papiers
                await Clipboard.setData(ClipboardData(text: code));

                // On ferme le dialogue
                Navigator.pop(context);

                // On affiche une confirmation à l'utilisateur [2]
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Code copied to clipboard!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("📚 Collection"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_location_alt), // Icône de "plus" avec localisation
              onPressed: () => _showAddCoordinateDialog(context), // Ouvre la fenêtre de saisie
              tooltip: "Add coordinate",
            ),
          ],
        ),
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
                    leading: SizedBox(width: 40,
                      child: Text(
                        pt.source, style: const TextStyle(fontSize: 24),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,),),
                    title: Text(
                        "${pt.latitude.toStringAsFixed(4)}, ${pt.longitude
                            .toStringAsFixed(4)}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Saved on: ${pt.timestamp}\nAlt: ${pt.altitude}m"),
                        // On garde la date
                        const SizedBox(height: 8),
                        // Petit espace

                        // AJOUT DU CHAMP DE TEXTE
                        TextField(
                            decoration: const InputDecoration(
                              hintText: "Add a note here...",
                              border: OutlineInputBorder(),
                              // Cadre autour de la zone
                              isDense: true, // Réduit la taille pour tenir dans la liste
                            ),
                            // On affiche la note actuelle stockée dans l'objet
                            controller: TextEditingController(
                                text: pt.userNote),

                            // ACTION : Sauvegarde quand l'utilisateur appuie sur "Entrée"
                            onSubmitted: (value) async {
                              // On appelle la méthode de mise à jour du StorageService (étape 2)
                              await _storage.updatePoint(index, value);
                              await _loadList();
                              // Petit message de confirmation
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Note updated!")),
                                );
                              }
                            }
                        ),
                        const SizedBox(height: 8),
                        // NOUVEAU BOUTON : See on map
                        ElevatedButton.icon(
                          onPressed: () {
                            // On déclenche le callback avec les coordonnées du point
                            widget.onSeeOnMap(LatLng(pt.latitude, pt.longitude));
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text("See on map"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, // Important pour que la ligne ne prenne pas toute la largeur
                      children: [
                        // BOUTON PARTAGER (Génère le code)
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.blue),
                          onPressed: () {
                            // On génère le code via le service de partage
                            String code = SharingService.generateCode(pt);
                            _showShareDialog(context, code); // Affiche le code à copier
                          },
                        ),
                        // BOUTON SUPPRIMER (Déjà existant dans votre code)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _storage.deleteAtIndex(index);
                            _loadList();
                          },
                        ),
                      ],
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