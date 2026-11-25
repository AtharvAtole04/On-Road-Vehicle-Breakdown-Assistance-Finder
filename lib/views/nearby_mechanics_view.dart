// lib/views/nearby_mechanics_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../services/nearby_service.dart';
import '../../services/sos_service.dart';
import '../../utils/map_launcher.dart';

class NearbyMechanicsView extends StatefulWidget {
  final double lat;
  final double lng;
  const NearbyMechanicsView({Key? key, required this.lat, required this.lng})
      : super(key: key);

  @override
  State<NearbyMechanicsView> createState() => _NearbyMechanicsViewState();
}

class _NearbyMechanicsViewState extends State<NearbyMechanicsView> {
  bool _loading = true;
  List<NearbyPlace> _places = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await NearbyService.findMechanics(
      lat: widget.lat,
      lon: widget.lng,
      radiusMeters: 200000,
      limit: 10,
    );
    // sort by distance
    list.sort((a, b) => a.distanceTo(LatLng(widget.lat, widget.lng)).compareTo(
          b.distanceTo(LatLng(widget.lat, widget.lng)),
        ));
    setState(() {
      _places = list;
      _loading = false;
    });
  }

  Widget _mechanicCard(NearbyPlace p) {
    final dist = p.distanceTo(LatLng(widget.lat, widget.lng));
    final km = dist >= 1000
        ? '${(dist / 1000).toStringAsFixed(1)} km'
        : '${dist.toInt()} m';
    final name = p.name ?? (p.tags['operator'] ?? 'Unnamed Mechanic');
    final phone = p.tags['phone'] ?? p.tags['contact:phone'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            leading: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA6), Color(0xFF0F9D58)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.build_rounded,
                  color: Colors.white, size: 30),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                (p.tags['addr:street'] ?? '') +
                    (p.tags['addr:housenumber'] != null
                        ? ', ${p.tags['addr:housenumber']}'
                        : ''),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(km,
                      style: const TextStyle(fontSize: 12, color: Colors.teal)),
                ),
                //  const SizedBox(height: 8),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Call mechanic',
                icon: const Icon(
                  Icons.call,
                  color: Colors.teal,
                ),
                onPressed: () async {
                  if (phone != null) {
                    await SosService.dialNumber(phone);
                  } else {
                    Get.snackbar(
                        'No Phone', 'Phone number not available for this place',
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.black);
                  }
                },
              ),
              IconButton(
                tooltip: 'Open in Google Maps',
                icon: const Icon(
                  Icons.map_outlined,
                  color: Colors.blueAccent,
                ),
                onPressed: () => openMap(p.lat, p.lon, label: name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerGradient() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F9D58), Color(0xFF00BFA6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.handyman, color: Color(0xFF00BFA6), size: 30),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Nearby Mechanics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                color: Colors.grey.shade400, size: 90),
            const SizedBox(height: 16),
            const Text(
              'No mechanics found nearby',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing your search radius or check your location settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.teal),
          const SizedBox(height: 20),
          Text('Finding nearby mechanics...',
              style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _headerGradient(),
          Expanded(
            child: _loading
                ? _loadingIndicator()
                : _places.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: Colors.teal,
                        onRefresh: _load,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _places.length,
                          itemBuilder: (_, i) => _mechanicCard(_places[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: _load,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('Refresh'),
      ),
    );
  }
}
