// lib/views/map/map_picker_view.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geocode_service.dart';

class MapPickerView extends StatefulWidget {
  final LatLng? initialPosition;
  const MapPickerView({Key? key, this.initialPosition}) : super(key: key);

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  final MapController _mapController = MapController();
  LatLng? _picked;
  String? _address;
  bool _loadingAddress = false;
  static const double _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    // try initial position or device position
    if (widget.initialPosition != null) {
      _picked = widget.initialPosition;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _moveTo(_picked!, 15.0);
          _fetchAddressFor(_picked!);
        }
      });
    } else {
      _determinePositionAndCenter();
    }
  }

  Future<void> _determinePositionAndCenter() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 6),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = ll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _moveTo(ll, 15.0);
      });
      _fetchAddressFor(ll);
    } catch (e) {
      debugPrint('determinePosition failed: $e');
      final fallback = LatLng(28.6139, 77.2090);
      setState(() => _picked = fallback);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _moveTo(fallback, 12.0);
      });
      _fetchAddressFor(fallback);
    }
  }

  void _moveTo(LatLng pos, double zoom) {
    try {
      _mapController.move(pos, zoom);
    } catch (e) {
      debugPrint('map move failed (controller not ready): $e');
    }
  }

  Future<void> _fetchAddressFor(LatLng p) async {
    setState(() {
      _loadingAddress = true;
      _address = null;
    });
    final addr = await GeocodeService.reverseGeocode(p.latitude, p.longitude);
    if (mounted) {
      setState(() {
        _address = addr ?? '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
        _loadingAddress = false;
      });
    }
  }

  void _onTap(LatLng latlng) {
    setState(() => _picked = latlng);
    _moveTo(latlng, _defaultZoom);
    _fetchAddressFor(latlng);

    // give user feedback to press Confirm
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location picked — press Confirm to use it'), duration: Duration(milliseconds: 900)));
  }

  void _confirmAndReturn() {
    if (_picked == null) return;
    final result = <String, dynamic>{
      'lat': _picked!.latitude,
      'lng': _picked!.longitude,
      'address': _address ?? '${_picked!.latitude},${_picked!.longitude}',
    };
    debugPrint('MapPicker confirm -> returning: $result');
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? LatLng(28.6139, 77.2090);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: _picked == null ? null : _confirmAndReturn,
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onTap: (tapPosition, latlng) => _onTap(latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.road_side_assistent',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_on, size: 48, color: Colors.red),
                    ),
                  ],
                ),
            ],
          ),

          // address bar at bottom
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
                child: Row(
                  children: [
                    Expanded(
                      child: _loadingAddress
                          ? Row(children: const [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 10), Text('Looking up address...')])
                          : Text(_address ?? 'Tap on map to pick a location', style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Use current location',
                      onPressed: () async {
                        await _determinePositionAndCenter();
                      },
                      icon: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: _picked == null ? null : _confirmAndReturn,
          label: const Text('Confirm location'),
          icon: const Icon(Icons.check),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
