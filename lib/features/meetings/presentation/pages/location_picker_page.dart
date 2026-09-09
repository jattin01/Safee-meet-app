import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_constants.dart';
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
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _showSuggestions = false;
  


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

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);
    
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
        // Camera move triggers onCameraIdle, which resolves the address
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not found: "$query"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json',
          queryParameters: {
            'input': query,
            'key': AppConstants.googleMapsApiKey,
            'components': 'country:in', // Optional: prioritize Indian results
          },
        );
        
        if (response.data['status'] == 'OK') {
          final predictions = response.data['predictions'] as List;
          if (mounted) {
            setState(() {
              _suggestions = predictions.map<Map<String, String>>((p) => {
                'description': p['description'] as String,
                'place_id': p['place_id'] as String,
              }).toList();
              _showSuggestions = true;
            });
          }
        } else {
          debugPrint('Places API Error: ${response.data['status']} - ${response.data['error_message']}');
        }
      } catch (e) {
        debugPrint('Places API Exception: $e');
      }
    });
  }

  void _onSuggestionSelected(String description) {
    _searchController.text = description;
    _searchLocation(description);
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
            myLocationEnabled: true,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _searchLocation,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 15, color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Search for a place...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                              ),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  _searchFocus.unfocus();
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        if (_showSuggestions && _suggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _suggestions.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on, color: Colors.grey),
                                  title: Text(
                                    suggestion['description'] ?? '',
                                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _onSuggestionSelected(suggestion['description']!),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
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
