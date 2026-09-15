import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../network/api_client.dart';

class IndiaAddress {
  const IndiaAddress({
    required this.line1,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String line1;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final double latitude;
  final double longitude;
}

class IndiaLocationService {
  const IndiaLocationService();

  Future<Position> ensureLocationAndGetPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      await Geolocator.openLocationSettings();
      throw const ApiException(
        'Please enable location services, then tap Use current location again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw const ApiException(
        'Location permission is blocked. Enable it in app settings, then retry.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const ApiException('Location permission is required.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    ).timeout(const Duration(seconds: 20));
  }

  Future<IndiaAddress> currentAddress() async {
    final position = await ensureLocationAndGetPosition();

    List<Placemark> placemarks = const [];
    try {
      placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      placemarks = const [];
    }
    if (placemarks.isEmpty) {
      return IndiaAddress(
        line1: 'Current location',
        area: '',
        city: '',
        state: '',
        pincode: '',
        country: 'India',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    final place = placemarks.first;
    final country = place.country ?? '';
    final isoCountry = place.isoCountryCode ?? '';
    if (country.toLowerCase() != 'india' && isoCountry.toUpperCase() != 'IN') {
      throw const ApiException('VyparHub currently supports India only.');
    }

    final streetParts = [
      place.name,
      place.street,
      place.subLocality,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

    return IndiaAddress(
      line1: streetParts.toSet().join(', '),
      area: place.subAdministrativeArea?.isNotEmpty == true
          ? place.subAdministrativeArea!
          : place.locality ?? '',
      city: place.locality?.isNotEmpty == true
          ? place.locality!
          : place.subAdministrativeArea ?? '',
      state: place.administrativeArea ?? '',
      pincode: place.postalCode ?? '',
      country: country.isNotEmpty ? country : 'India',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
