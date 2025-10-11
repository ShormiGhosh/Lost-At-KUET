import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  MapPickerResult({required this.latitude, required this.longitude, required this.address});
}

class MapPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  const MapPickerPage({Key? key, this.initialPosition}) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class MapViewerPage extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? title;

  const MapViewerPage({Key? key, this.latitude, this.longitude, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng center = (latitude != null && longitude != null)
      ? LatLng(latitude!, longitude!)
      : LatLng(22.8130, 89.5616);

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Location'),
        backgroundColor: const Color(0xFF292929),
      ),
      body: FlutterMap(
        options: MapOptions(center: center, zoom: 16),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.lostatkuet',
          ),
          if (latitude != null && longitude != null)
            MarkerLayer(markers: [
              Marker(
                point: center,
                width: 48,
                height: 48,
                builder: (ctx) => const Icon(Icons.place, color: Colors.red, size: 36),
              )
            ])
        ],
      ),
    );
  }
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final MapController _mapController;
  LatLng? _picked;
  bool _loading = false;
  bool _highlight = false;

  static final LatLng _kuetCenter = LatLng(22.8130, 89.5616);
  // Default bounding box (fallback) around KUET campus to restrict initial view and zooming
  static final LatLngBounds _kuetBoundsFallback = LatLngBounds(
    LatLng(22.8105, 89.5585), // SW
    LatLng(22.8165, 89.5645), // NE
  );

  // ---------- FORCE VIEW (edit these to match the screenshot exactly) ----------
  // Set this to true to force the picker to open at the coordinates and bounds below.
  static const bool _forceView = true;
  // Center coordinates to force when opening the map (edited from user input)
  static final LatLng _forceCenter = LatLng(22.898940, 89.504403);
  // Bounding box to fit when forcing the view. Adjust to make the screenshot area visible.
  // These deltas are intentionally small to show a neighborhood-sized area; tweak as needed.
  static final LatLngBounds _forceBounds = LatLngBounds(
    LatLng(22.896940, 89.501403), // SW (center - ~0.0020 lat, -0.0030 lon)
    LatLng(22.900940, 89.507403), // NE (center + ~0.0020 lat, +0.0030 lon)
  );
  // Forced zoom when centering (tweak this if you want closer/further)
  static const double _forceZoom = 17.5;
  // -----------------------------------------------------------------------------

  // Dynamic values resolved at runtime. If resolution fails, fall back to static values above.
  LatLng? _resolvedKuetCenter;
  LatLngBounds? _resolvedKuetBounds;
  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String? _selectedSearchName;
  LatLng? _pendingSelection;

  final List<Map<String, dynamic>> _campusPlaces = [
  {'name': 'Main Gate', 'pos': LatLng(22.8140, 89.5618)},
  {'name': 'Pocket Gate', 'pos': LatLng(22.8128, 89.5605)},
  {'name': 'IT Gate', 'pos': LatLng(22.8138, 89.5626)},
  {'name': 'Cafeteria', 'pos': LatLng(22.8133, 89.5620)},
  {'name': 'Academic Building', 'pos': LatLng(22.8145, 89.5612)},
  {'name': 'Civil Building', 'pos': LatLng(22.8150, 89.5610)},
  {'name': 'EEE Building', 'pos': LatLng(22.8148, 89.5620)},
  {'name': 'Mecha Building', 'pos': LatLng(22.8142, 89.5606)},
  {'name': 'Science Building', 'pos': LatLng(22.8136, 89.5610)},
  {'name': 'URP Building', 'pos': LatLng(22.8129, 89.5622)},
  {'name': 'Leather', 'pos': LatLng(22.8131, 89.5630)},
  {'name': 'Central Field', 'pos': LatLng(22.8146, 89.5619)},
  {'name': 'Education Section', 'pos': LatLng(22.8125, 89.5615)},
  {'name': 'Shahid Minar', 'pos': LatLng(22.8137, 89.5614)},
  {'name': 'IT Park', 'pos': LatLng(22.8152, 89.5625)},
  {'name': 'Masjid', 'pos': LatLng(22.8139, 89.5609)},
  {'name': 'Mandir', 'pos': LatLng(22.8132, 89.5609)},
  {'name': 'Durbar Bangla', 'pos': LatLng(22.8149, 89.5631)},
  {'name': 'Medical Center', 'pos': LatLng(22.8127, 89.5628)},
  {'name': 'SWC', 'pos': LatLng(22.8141, 89.5617)},
  {'name': 'Mukto Moncho', 'pos': LatLng(22.8134, 89.5624)},
  {'name': 'Khajar Pukur', 'pos': LatLng(22.8126, 89.5632)},
  {'name': 'Poddo Pukur', 'pos': LatLng(22.8155, 89.5611)},
  {'name': 'IT Pukur', 'pos': LatLng(22.8130, 89.5635)},
  // core campus places
  {'name': 'Central Library', 'pos': LatLng(22.8139, 89.5612)},
  {'name': 'Central Computer Centre', 'pos': LatLng(22.8140, 89.5616)},
  {'name': 'IEM Department', 'pos': LatLng(22.8129, 89.5608)},
  {'name': 'ECE Department', 'pos': LatLng(22.8129, 89.5602)},
  {'name': 'Architecture and URP', 'pos': LatLng(22.8130, 89.5600)},
  {'name': 'LE Department', 'pos': LatLng(22.8135, 89.5609)},
  {'name': 'ME Department', 'pos': LatLng(22.8138, 89.5610)},
  {'name': 'Mechanical Workshop', 'pos': LatLng(22.8146, 89.5614)},
  {'name': 'Administration Building', 'pos': LatLng(22.8144, 89.5624)},
  {'name': 'Tennis Court', 'pos': LatLng(22.8147, 89.5628)},
  {'name': 'Park', 'pos': LatLng(22.8142, 89.5615)},
  {'name': 'KUET Main Playground', 'pos': LatLng(22.8135, 89.5613)},
  {'name': 'Rokeya Hall', 'pos': LatLng(22.8137, 89.5628)},
  {'name': 'Central Canteen', 'pos': LatLng(22.8131, 89.5610)},
  {'name': 'Central Workshop', 'pos': LatLng(22.8143, 89.5607)},
  {'name': 'Library Annex', 'pos': LatLng(22.8138, 89.5610)},
  {'name': 'KUET Post Office', 'pos': LatLng(22.8132, 89.5617)},
  {'name': 'KUET Guest House', 'pos': LatLng(22.8149, 89.5629)},
  {'name': 'M A Rashid Hall', 'pos': LatLng(22.8150, 89.5615)},
  {'name': 'Rolexa Hall', 'pos': LatLng(22.8140, 89.5622)},
  {'name': 'Central Lab', 'pos': LatLng(22.8133, 89.5611)},
  {'name': 'Sports Complex', 'pos': LatLng(22.8148, 89.5630)},
  {'name': 'Staff Quarters', 'pos': LatLng(22.8153, 89.5620)},
  {'name': 'KUET Residential Area', 'pos': LatLng(22.8155, 89.5635)},
  // additional places from screenshots
  {'name': 'KUET Dighi', 'pos': LatLng(22.8130, 89.5613)},
  {'name': 'Central Shaheed Minar', 'pos': LatLng(22.8145, 89.5620)},
  {'name': 'KUET Mosque Pond', 'pos': LatLng(22.8130, 89.5619)},
  {'name': 'IT Incubation Centre', 'pos': LatLng(22.8146, 89.5622)},
  {'name': 'Lalan Shah Hall', 'pos': LatLng(22.8122, 89.5608)},
  {'name': 'Amar Ekushey Hall', 'pos': LatLng(22.8124, 89.5609)},
  {'name': 'Teligati Road', 'pos': LatLng(22.8120, 89.5610)},
  {'name': 'KUET Incubation Centre', 'pos': LatLng(22.8146, 89.5622)},
  {'name': 'Central Library Annex', 'pos': LatLng(22.8138, 89.5611)},
  {'name': 'Medical Center (KUET)', 'pos': LatLng(22.8136, 89.5618)},
  {'name': 'KUET Playground', 'pos': LatLng(22.8135, 89.5613)},
  {'name': 'Cafeteria (Central)', 'pos': LatLng(22.8130, 89.5610)},
  {'name': 'Janata Bank (KUET)', 'pos': LatLng(22.8130, 89.5610)},
  {'name': 'Fulbarigate Bazaar (near KUET)', 'pos': LatLng(22.8175, 89.5645)},
  {'name': 'Old KUET Road', 'pos': LatLng(22.8125, 89.5612)},
  {'name': 'KUET Residential Block A', 'pos': LatLng(22.8156, 89.5638)},
  {'name': 'KUET Residential Block B', 'pos': LatLng(22.8158, 89.5632)},
];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final LatLng mainGate = _campusPlaces.first['pos'] as LatLng;
    _picked = widget.initialPosition ?? mainGate;

    if (widget.initialPosition == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // small delay to ensure the map controller is attached and ready
        await Future.delayed(const Duration(milliseconds: 300));
        // If _forceView is enabled, use the forced center/bounds/zoom first.
        if (_forceView) {
          try {
            _resolvedKuetCenter = _forceCenter;
            _resolvedKuetBounds = _forceBounds;
            _mapController.move(_forceCenter, _forceZoom);
            _mapController.fitBounds(_forceBounds, options: const FitBoundsOptions(padding: EdgeInsets.all(24)));
          } catch (_) {}
        } else {
          // Try to resolve KUET center from Nominatim to ensure accurate placement
          try {
            final resolved = await _resolveKuetCenter();
            if (resolved != null) {
              _resolvedKuetCenter = resolved;
              // compute a small bounding box around the resolved center
              const latDelta = 0.0045; // ~500m
              const lonDelta = 0.0060; // ~600m
              _resolvedKuetBounds = LatLngBounds(
                LatLng(resolved.latitude - latDelta, resolved.longitude - lonDelta),
                LatLng(resolved.latitude + latDelta, resolved.longitude + lonDelta),
              );
              _mapController.move(resolved, 17.5);
              _mapController.fitBounds(_resolvedKuetBounds!, options: const FitBoundsOptions(padding: EdgeInsets.all(24)));
            } else {
              // fallback
              _mapController.move(mainGate, 17.5);
              _mapController.fitBounds(_kuetBoundsFallback, options: const FitBoundsOptions(padding: EdgeInsets.all(24)));
            }
          } catch (_) {
            try {
              _mapController.move(mainGate, 17.5);
              _mapController.fitBounds(_kuetBoundsFallback, options: const FitBoundsOptions(padding: EdgeInsets.all(24)));
            } catch (_) {}
          }
        }

        if (mounted) setState(() => _highlight = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _highlight = false);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String q) async {
    final raw = q.trim();
    final qTrim = raw;
    if (qTrim.isEmpty) {
      // show all local campus places when the query is empty
      final all = <Map<String, dynamic>>[];
      for (final place in _campusPlaces) {
        final LatLng p = place['pos'] as LatLng;
        all.add({'name': place['name'] as String, 'lat': p.latitude, 'lon': p.longitude, 'source': 'local'});
      }
      setState(() {
        _searchResults = all;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchResults = [];
    });
    try {
  final qLower = q.toLowerCase().trim();
      // 1) local campus matches (substring)
      final local = <Map<String, dynamic>>[];
      for (final place in _campusPlaces) {
        final name = (place['name'] as String).toLowerCase();
        if (name.contains(qLower)) {
          final LatLng p = place['pos'] as LatLng;
          local.add({'name': place['name'] as String, 'lat': p.latitude, 'lon': p.longitude, 'source': 'local'});
        }
      }
      // If there's an exact local match, select it immediately
      Map<String, dynamic>? exactLocal;
      for (final e in local) {
        if ((e['name'] as String).toLowerCase() == qLower) {
          exactLocal = e;
          break;
        }
      }
      if (exactLocal != null) {
        // immediate selection: return the result to caller
        if (mounted) Navigator.of(context).pop(MapPickerResult(latitude: exactLocal['lat'] as double, longitude: exactLocal['lon'] as double, address: exactLocal['name'] as String));
        return;
      }
      // start with local matches
      final results = <Map<String, dynamic>>[];
      results.addAll(local);
      // Limit search to KUET approximate bbox to improve relevance
      final viewbox = '${_kuetBoundsFallback.south},${_kuetBoundsFallback.west},${_kuetBoundsFallback.north},${_kuetBoundsFallback.east}';
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(q)}&format=jsonv2&limit=10&viewbox=$viewbox&bounded=1');
      final resp = await http.get(url, headers: {'User-Agent': 'LostAtKuet/1.0 (youremail@example.com)'});
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        
        for (final item in list) {
          final Map<String, dynamic> it = Map<String, dynamic>.from(item as Map);
          final lat = double.tryParse(it['lat']?.toString() ?? '');
          final lon = double.tryParse(it['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            results.add({'name': it['display_name'] ?? it['name'] ?? q, 'lat': lat, 'lon': lon, 'source': 'osm'});
          }
        }
        // Append OSM results after local matches
        final osmResults = <Map<String, dynamic>>[];
        for (final item in list) {
          final Map<String, dynamic> it = Map<String, dynamic>.from(item as Map);
          final lat = double.tryParse(it['lat']?.toString() ?? '');
          final lon = double.tryParse(it['lon']?.toString() ?? '');
          if (lat != null && lon != null) osmResults.add({'name': it['display_name'] ?? it['name'] ?? q, 'lat': lat, 'lon': lon, 'source': 'osm'});
        }
        results.addAll(osmResults);
        setState(() => _searchResults = results);
      }
    } catch (_) {}
    setState(() => _searching = false);
  }

  Future<LatLng?> _resolveKuetCenter() async {
    try {
      final q = Uri.encodeQueryComponent('Khulna University of Engineering and Technology');
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=jsonv2&limit=1');
      final resp = await http.get(url, headers: {'User-Agent': 'LostAtKuet/1.0 (youremail@example.com)'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      // Ask Nominatim for detailed name/address info and prefer building/POI level (zoom=18)
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=18&addressdetails=1&namedetails=1&extratags=1');
      final resp = await http.get(url, headers: {'User-Agent': 'LostAtKuet/1.0 (youremail@example.com)'});
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;

        // Prefer explicit name field if present
        if (json['name'] != null && (json['name'] as String).trim().isNotEmpty) {
          return json['name'] as String;
        }

        // Next prefer specific address components
        if (json['address'] is Map<String, dynamic>) {
          final Map<String, dynamic> addr = Map<String, dynamic>.from(json['address'] as Map);
          // priority list of address keys that represent specific POIs/buildings
          final keys = ['building', 'amenity', 'attraction', 'tourism', 'house', 'public_building', 'office', 'residential', 'hotel', 'university', 'college'];
          for (final k in keys) {
            if (addr.containsKey(k) && (addr[k] as String).trim().isNotEmpty) {
              return addr[k] as String;
            }
          }
        }

        // If Nominatim returns a generic campus name (e.g., KUET) or no specific POI,
        // fall back to the nearest campus POI from our local list if it's close enough.
        try {
          final Distance distance = Distance();
          double best = double.maxFinite;
          String? bestName;
          for (final place in _campusPlaces) {
            final LatLng p = place['pos'] as LatLng;
            final d = distance.as(LengthUnit.Meter, LatLng(lat, lon), p);
            if (d < best) {
              best = d;
              bestName = place['name'] as String;
            }
          }
          // If the nearest campus POI is within ~120 meters, use its name (widened threshold)
          if (bestName != null && best < 120.0) {
            return bestName;
          }
        } catch (_) {}

        // Fallback to display_name if available
        if (json.containsKey('display_name')) return json['display_name'] as String;
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        backgroundColor: const Color(0xFF292929),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loading
                ? null
                : () async {
                    // If there's a pending selection from search, prefer that (do not finalize until Select)
                    final LatLng? finalizePoint = _pendingSelection ?? _picked;
                    if (finalizePoint == null) return;
                    setState(() => _loading = true);
                    String address;
                    if (_selectedSearchName != null) {
                      address = _selectedSearchName!;
                    } else {
                      address = await _reverseGeocode(finalizePoint.latitude, finalizePoint.longitude);
                    }
                    // move map to finalize point for UX consistency
                    try {
                      _mapController.move(finalizePoint, 17.5);
                    } catch (_) {}
                    setState(() => _loading = false);
                    final result = MapPickerResult(latitude: finalizePoint.latitude, longitude: finalizePoint.longitude, address: address);
                    // clear pending selection after finalize
                    _pendingSelection = null;
                    if (mounted) Navigator.of(context).pop(result);
                  },
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text('Select', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _picked ?? _resolvedKuetCenter ?? _kuetCenter,
              zoom: 17.5,
              minZoom: 14.0,
              maxZoom: 19.0,
              // NOTE: removed maxBounds to allow free panning/zooming across the map
              interactiveFlags: InteractiveFlag.all,
              onTap: (tapPos, latlng) {
                setState(() {
                  _picked = latlng;
                  // user tapped the map manually -> clear any previous search selection/pending
                  _selectedSearchName = null;
                  _pendingSelection = null;
                });
                try {
                  // center and zoom to the tapped location so the campus area is visible
                  _mapController.move(latlng, 17.5);
                } catch (_) {}
              },
            ),
            children: [
              TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.example.lostatkuet'),
              MarkerLayer(
                markers: [
                  for (final place in _campusPlaces)
                    Marker(
                      point: place['pos'] as LatLng,
                      width: 48,
                      height: 48,
                      builder: (ctx) {
                        final name = place['name'] as String;
                        final LatLng pos = place['pos'] as LatLng;
                        final bool isSelected = _picked != null && (_picked!.latitude == pos.latitude && _picked!.longitude == pos.longitude);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _picked = pos;
                            });
                            try {
                              _mapController.move(pos, 17.5);
                            } catch (_) {}
                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name selected'), duration: const Duration(seconds: 1)));
                          },
                          child: Icon(Icons.location_on, color: isSelected ? Colors.red : Colors.blueAccent, size: 32),
                        );
                      },
                    ),
                  if (_picked != null)
                    Marker(point: _picked!, width: 56, height: 56, builder: (ctx) => const Icon(Icons.place, color: Colors.red, size: 36)),
                ],
              ),
            ],
          ),

          // Search bar overlay
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(hintText: 'Search KUET place (e.g. Rokeya Hall)', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                          onSubmitted: (v) => _searchPlaces(v),
                          onChanged: (v) {
                            // show local suggestions immediately while typing
                            final q = v.toLowerCase().trim();
                            if (q.isEmpty) {
                              setState(() {
                                _searchResults = [];
                              });
                            } else {
                              final matches = <Map<String, dynamic>>[];
                              for (final place in _campusPlaces) {
                                final name = (place['name'] as String).toLowerCase();
                                if (name.contains(q)) {
                                  final LatLng p = place['pos'] as LatLng;
                                  matches.add({'name': place['name'] as String, 'lat': p.latitude, 'lon': p.longitude, 'source': 'local'});
                                }
                              }
                              setState(() {
                                _searchResults = matches;
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: _searching ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                        onPressed: _searching ? null : () => _searchPlaces(_searchController.text),
                      ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    height: 160,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                    child: ListView.separated(
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = _searchResults[i];
                        return ListTile(
                          title: Text(r['name'] as String, style: const TextStyle(fontSize: 13)),
                          onTap: () {
                            final lat = r['lat'] as double;
                            final lon = r['lon'] as double;
                            final LatLng p = LatLng(lat, lon);
                            setState(() {
                              // set as pending selection (do not auto-navigate/finalize)
                              _pendingSelection = p;
                              _searchResults = [];
                              _searchController.text = r['name'] as String;
                              _selectedSearchName = r['name'] as String;
                            });
                            // do not move the map or finalize until user presses Select
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            left: 8,
            right: 8,
            bottom: 12,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _campusPlaces.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final place = _campusPlaces[i];
                  return ActionChip(
                    label: Text(place['name'] as String, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      final LatLng p = place['pos'] as LatLng;
                      _mapController.move(p, 17.0);
                      setState(() {
                        _picked = p;
                      });
                    },
                  );
                },
              ),
            ),
          ),

          if (_highlight)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                child: const Text('Centered on KUET — Main Gate', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
              ),
            ),

          // ...existing code...
        ],
      ),
    );
  }
}
