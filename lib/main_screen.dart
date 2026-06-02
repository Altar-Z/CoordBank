import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // To handle the Position type
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/map_screen.dart';
import 'package:latlong2/latlong.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  LatLng? _mapCenterOverride;
  // Shared state: holds the last position fetched by HomeScreen
  Position? _currentPosition;

  // Callback to update the shared position from HomeScreen
  void _updatePosition(Position pos) {
    setState(() {
      _currentPosition = pos;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // On réinitialise l'override si on change d'onglet manuellement
      if (index != 1) _mapCenterOverride = null;
    });
  }

  void _handleSeeOnMap(LatLng coords) {
    setState(() {
      _mapCenterOverride = coords; // On enregistre les coordonnées
      _selectedIndex = 1;         // On bascule sur l'onglet Map (index 1)
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(onPositionFetched: (pos) => setState(() => _currentPosition = pos)),
      // On passe l'override à la Map
      MapScreen(currentPosition: _currentPosition, targetLocation: _mapCenterOverride),
      // On passe la fonction de rappel à la Collection
      CollectionScreen(currentPosition: _currentPosition, onSeeOnMap: _handleSeeOnMap),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Collection"),
        ],
      ),
    );
  }
}
  /*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          // Pass the callback to HomeScreen
          HomeScreen(onPositionFetched: _updatePosition),
          // Pass the current shared position to CollectionScreen
          CollectionScreen(currentPosition: _currentPosition),
          MapScreen(currentPosition: _currentPosition),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.collections), label: 'Collection'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
   */