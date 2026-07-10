import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/primary_button.dart';

typedef PickedLocation = ({double latitude, double longitude, String address});

/// Full-screen "drop a pin" location picker. The pin stays fixed at the
/// center of the screen; the map moves underneath it. On confirm, the
/// centered coordinate is reverse-geocoded into a human-readable address.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _fallback = LatLng(28.6139, 77.2090); // New Delhi

  GoogleMapController? _controller;
  LatLng _center = _fallback;
  String? _address;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!granted) {
        final requested = await Geolocator.requestPermission();
        if (requested != LocationPermission.always &&
            requested != LocationPermission.whileInUse) {
          await _resolveAddress(_center);
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition();
      final here = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _center = here);
      _controller?.animateCamera(CameraUpdate.newLatLng(here));
      await _resolveAddress(here);
    } catch (_) {
      await _resolveAddress(_center);
    }
  }

  Future<void> _resolveAddress(LatLng target) async {
    setState(() => _resolvingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      final p = placemarks.first;
      final parts = [p.street, p.locality, p.administrativeArea]
          .where((s) => s != null && s.isNotEmpty)
          .toList();
      setState(() {
        _address = parts.isNotEmpty
            ? parts.join(', ')
            : '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _resolvingAddress = false;
      });
    } catch (_) {
      setState(() {
        _address =
            '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _resolvingAddress = false;
      });
    }
  }

  void _confirm() {
    if (_address == null) return;
    Navigator.of(context).pop<PickedLocation>((
      latitude: _center.latitude,
      longitude: _center.longitude,
      address: _address!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _controller = c,
            onCameraMove: (position) => _center = position.target,
            onCameraIdle: () => _resolveAddress(_center),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, color: AppColors.primary, size: 44),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED LOCATION',
                      style: GoogleFonts.inter(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _resolvingAddress
                          ? 'Locating…'
                          : (_address ?? 'Move the map to drop the pin'),
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Confirm Location',
                      onPressed: (_address == null || _resolvingAddress) ? null : _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
