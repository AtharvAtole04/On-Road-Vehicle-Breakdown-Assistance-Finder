// lib/views/user/order_form_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:roadside_assistant/controllers/auth_controller.dart';
import 'package:roadside_assistant/services/geocode_service.dart';
import 'package:roadside_assistant/services/sos_service.dart';
import 'package:roadside_assistant/views/feedback_view.dart';
import 'package:roadside_assistant/views/nearby_mechanics_view.dart';

import '../../controllers/order_controller.dart';
import '../map/map_picker_view.dart'; // ensure this path is correct
import '../../utils/map_launcher.dart'; // optional: used to open map from preview

class OrderFormView extends StatefulWidget {
  const OrderFormView({Key? key}) : super(key: key);

  @override
  _OrderFormViewState createState() => _OrderFormViewState();
}

class _OrderFormViewState extends State<OrderFormView> {
  final AuthController auth = Get.find<AuthController>();
  final OrderController orderC = Get.find<OrderController>();
  final TextEditingController locationC = TextEditingController();
  String selectedService = 'mechanic';
  String selectedFuelType = 'Petrol';
  double selectedFuelCapacity = 5.0;
  bool isTowing = false;
  String vehicleIssue = '';

  // map preview / picked values
  double? selectedLat;
  double? selectedLng;
  String? selectedAddress;
  final MapController _previewMapController = MapController();
  static const double _previewZoom = 15.0;

  final Map<String, IconData> serviceIcons = {
    'mechanic': Icons.build_circle_rounded,
    'petrol': Icons.local_gas_station,
    'towing': Icons.local_shipping,
  };

  @override
  void initState() {
    super.initState();
    // If the caller supplied initial args (optional), populate them
    final args = Get.arguments;
    if (args is Map) {
      if (args['lat'] != null && args['lng'] != null) {
        selectedLat = (args['lat'] as num).toDouble();
        selectedLng = (args['lng'] as num).toDouble();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _previewMapController.move(
                LatLng(selectedLat!, selectedLng!), _previewZoom);
          } catch (_) {}
        });
      }
      if (args['address'] != null) {
        selectedAddress = args['address'] as String?;
        locationC.text = selectedAddress ?? '';
      }
      if (args['service'] != null) {
        selectedService = args['service'] as String;
      }
    }
  }

  Future<void> _openMapPickerAndHandleResult() async {
    // Do NOT use const MapPickerView() here; must be a fresh instance to get result reliably
    final res = await Get.to(() => MapPickerView());
    debugPrint('MapPicker returned: $res, type=${res?.runtimeType}');

    if (res == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No location selected')));
      return;
    }
    if (res is! Map) {
      debugPrint('Unexpected result type from MapPicker: ${res.runtimeType}');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid location result')));
      return;
    }

    try {
      final latRaw = res['lat'];
      final lngRaw = res['lng'];
      final addrRaw = res['address'];
      if (latRaw == null || lngRaw == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Picker returned no coordinates')));
        return;
      }
      final lat = (latRaw as num).toDouble();
      final lng = (lngRaw as num).toDouble();
      final addr = addrRaw?.toString();

      if (!mounted) return;
      setState(() {
        selectedLat = lat;
        selectedLng = lng;
        selectedAddress = addr;
        locationC.text = addr ?? '$lat,$lng';
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location selected: ${locationC.text}')));

      // recenter preview map after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _previewMapController.move(
              LatLng(selectedLat!, selectedLng!), _previewZoom);
        } catch (e) {
          debugPrint('preview move failed: $e');
        }
      });
    } catch (e, st) {
      debugPrint('Error parsing map picker result: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read picker result')));
    }
  }

  Widget _mapPreview() {
    if (selectedLat == null || selectedLng == null) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: TextButton.icon(
            onPressed: _openMapPickerAndHandleResult,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Pick location on map'),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        // open the full picker again if user wants to change
        await _openMapPickerAndHandleResult();
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            mapController: _previewMapController,
            options: MapOptions(
                // don't set center/zoom here for compatibility with flutter_map 8.x; we'll move controller explicitly
                //  interactiveFlags: InteractiveFlag.none,
                ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.road_side_assistent',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(selectedLat!, selectedLng!),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on,
                        size: 40, color: Colors.red.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInMaps() async {
    if (selectedLat != null && selectedLng != null) {
      await openMap(selectedLat!, selectedLng!,
          label: selectedAddress ?? locationC.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No coordinates available')));
    }
  }

  Future<void> _onPlaceRequestPressed() async {
    final locText = locationC.text.trim();
    if (locText.isEmpty && (selectedLat == null || selectedLng == null)) {
      Get.snackbar(
          'Missing location', 'Please pick a location or enter address',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // If we have coordinates, use placeOrderWithLocation (recommended)
    String? err;
    if (selectedLat != null && selectedLng != null) {
      err = await orderC.placeOrderWithLocation(
        serviceType: selectedService,
        location: locText.isNotEmpty
            ? locText
            : (selectedAddress ?? '${selectedLat!},${selectedLng!}'),
        lat: selectedLat!,
        lng: selectedLng!,
        fuelType: selectedService == 'petrol' ? selectedFuelType : null,
        fuelCapacity: selectedService == 'petrol' ? selectedFuelCapacity : null,
        isTowing: selectedService == 'towing',
        vehicleIssue: vehicleIssue,
      );
    } else {
      // fallback to existing method (without coordinates)
      err = await orderC.placeOrder(
        serviceType: selectedService,
        location: locText,
      );
    }

    if (err == null) {
      Get.back();
      Get.snackbar(
          '✅ Success', 'Your $selectedService request has been placed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100);
    } else {
      Get.snackbar('❌ Error', err,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header with gradient ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F9D58), Color(0xFF00BFA6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.car_repair,
                        color: Color(0xFF00BFA6), size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Request Roadside Help',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text('Find Mechanics near by'),
                    onPressed: () {
                      if (selectedLat == null || selectedLng == null) {
                        Get.snackbar(
                            'Pick location', 'Please pick a location first');
                        return;
                      }
                      Get.to(() => NearbyMechanicsView(
                          lat: selectedLat!, lng: selectedLng!));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Form card ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Row(
                        children: const [
                          Icon(Icons.miscellaneous_services,
                              color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Select Service Type',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Service dropdown
                      DropdownButtonFormField<String>(
                        value: selectedService,
                        items: serviceIcons.keys.map((key) {
                          return DropdownMenuItem(
                            value: key,
                            child: Row(
                              children: [
                                Icon(serviceIcons[key], color: Colors.teal),
                                const SizedBox(width: 10),
                                Text(key[0].toUpperCase() + key.substring(1),
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => selectedService = v!),
                        decoration: InputDecoration(
                          labelText: 'Service Type',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.teal, width: 1.5)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Vehicle Issue Selection
                      Row(
                        children: const [
                          Icon(Icons.report_problem_outlined, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Describe the vehicle issue',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (v) => setState(() => vehicleIssue = v),
                        decoration: InputDecoration(
                          hintText: 'e.g. Engine noise, Brake failure...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Puncture',
                          'Battery dead',
                          'Engine issue',
                          'Brake failure',
                          'Fuel issue',
                          'Towing'
                        ].map((issue) {
                          final isSelected = vehicleIssue == issue;
                          return ChoiceChip(
                            label: Text(issue),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                vehicleIssue = selected ? issue : '';
                              });
                            },
                            selectedColor: Colors.teal.shade100,
                            labelStyle: TextStyle(
                                color: isSelected ? Colors.teal : Colors.black),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      if (selectedService == 'petrol') ...[
                        const Text('Fuel Details',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedFuelType,
                                items: ['Petrol', 'Diesel'].map((e) {
                                  return DropdownMenuItem(
                                      value: e, child: Text(e));
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => selectedFuelType = v!),
                                decoration: InputDecoration(
                                  labelText: 'Fuel Type',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                value: selectedFuelCapacity,
                                items: [5.0, 10.0, 15.0, 20.0].map((e) {
                                  return DropdownMenuItem(
                                      value: e, child: Text('${e.toInt()} L'));
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => selectedFuelCapacity = v!),
                                decoration: InputDecoration(
                                  labelText: 'Capacity',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Location
                      Row(
                        children: const [
                          Icon(Icons.location_on_rounded, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Enter Your Location',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: locationC,
                        readOnly: false,
                        decoration: InputDecoration(
                          hintText: 'e.g. Near City Mall, Jaipur',
                          prefixIcon: const Icon(Icons.map_outlined,
                              color: Colors.teal),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedLat != null && selectedLng != null)
                                IconButton(
                                  tooltip: 'Open in Google Maps',
                                  icon:
                                      const Icon(Icons.map, color: Colors.teal),
                                  onPressed: _openInMaps,
                                ),
                              IconButton(
                                icon: const Icon(Icons.my_location,
                                    color: Colors.teal),
                                onPressed: _openMapPickerAndHandleResult,
                              ),
                            ],
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.teal, width: 1.5)),
                        ),
                        onTap: _openMapPickerAndHandleResult,
                      ),

                      const SizedBox(height: 14),

                      // Map preview (if coords exist)
                      if (selectedLat != null && selectedLng != null) ...[
                        Text('Selected Location',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _mapPreview(),
                        const SizedBox(height: 14),
                      ],

                      // Place Request Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: EdgeInsets.zero,
                            elevation: 6,
                          ).copyWith(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shadowColor:
                                MaterialStateProperty.all(Colors.transparent),
                          ),
                          onPressed: _onPlaceRequestPressed,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F9D58),
                                    Color(0xFF00BFA6)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.send, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Place Request',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
