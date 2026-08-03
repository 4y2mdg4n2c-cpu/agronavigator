import 'dart:async';

import 'package:agronavigator_app/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  StreamSubscription<Position>? _positionSubscription;

  LatLng? currentLatLng;

  @override
  void initState() {
    super.initState();

    _positionSubscription = _locationService
        .getPositionStream()
        .listen((Position position) {
      setState(() {
        currentLatLng = LatLng(
          position.latitude,
          position.longitude,
        );
      });

      _mapController.move(
        currentLatLng!,
        _mapController.camera.zoom,
      );
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(47.24405, 39.80821),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
            userAgentPackageName: 'ru.maxim.agronavigator',
          ),
          MarkerLayer(
            markers: currentLatLng == null
                ? []
                : [
                    Marker(
                      point: currentLatLng!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}