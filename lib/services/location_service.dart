import 'package:geolocator/geolocator.dart';
class LocationService {
  static Future<Position?> getCurrentPosition() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
  static double distanceBetween(double lat1, double lng1, double lat2, double lng2) =>
    Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  static String formatDistance(double km) => km < 1 ? '${(km * 1000).round()}m away' : '${km.toStringAsFixed(1)}km away';
}
