import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position> getPositionStream() async* {
    await Geolocator.requestPermission();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    yield* Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }
}