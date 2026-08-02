import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';

/// Layar pemilih titik lokasi lowongan di peta (OpenStreetMap).
/// Rekruter bisa tap/geser peta untuk menandai titik kantor/lokasi kerja,
/// atau pakai tombol "Lokasi Saya Saat Ini" (GPS). Hasil dikembalikan ke
/// PostJobScreen lewat `context.pop(LatLng(...))`.
class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  const LocationPickerScreen({super.key, required this.initialLat, required this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _point = LatLng(widget.initialLat, widget.initialLng);
  final _mapController = MapController();
  bool _locating = false;
  String? _error;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan perangkat.');
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = 'Layanan lokasi (GPS) perangkat sedang nonaktif.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _point = point);
      _mapController.move(point, 15);
    } catch (e) {
      setState(() => _error = 'Gagal mengambil lokasi saat ini: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 14,
              onTap: (tapPos, point) => setState(() => _point = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.growin.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _point,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.work_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.85), shape: const CircleBorder()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassPane(
                      borderRadius: 9999,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Tap peta untuk menandai lokasi kerja',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton(
              heroTag: 'useCurrentLocationFab',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.black,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GlassPane(
              borderRadius: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: AppColors.black),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_point.latitude.toStringAsFixed(6)}, ${_point.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 11.5)),
                  ],
                  const SizedBox(height: 12),
                  PrimaryPillButton(
                    label: 'Gunakan Titik Ini',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () => context.pop(_point),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
