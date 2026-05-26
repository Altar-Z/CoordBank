import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // To handle the Position type
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/map_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Shared state: holds the last position fetched by HomeScreen
  Position? _currentPosition;

  // Callback to update the shared position from HomeScreen
  void _updatePosition(Position pos) {
    setState(() {
      _currentPosition = pos;
    });
  }

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