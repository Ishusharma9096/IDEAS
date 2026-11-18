import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/gps_service.dart';
import '../../core/services/supabase_service.dart';
import '../transit/data/transit_repository.dart';
import '../transit/domain/transit_models.dart';

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({
    super.key,
    this.busId,
    this.from = '',
    this.to = '',
  });
  final String? busId;
  final String from, to;
  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  late final DeviceGPSService _gps;
  StreamSubscription<GpsFix>? _subscription;
  GpsFix? _fix;
  LatLng? _passengerLocation;
  final List<Marker> _stopMarkers = [];
  Timer? _ageTimer;
  BusService? _bus;
  final _map = MapController();
  bool _loadingGps = false;
  bool _locationBusy = false;
  bool _lastLocationLoaded = false;
  String? _gpsError;
  static const _center = LatLng(15.4909, 73.8278);
  static const _tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  @override
  void initState() {
    super.initState();
    _gps = DeviceGPSService();
    _ageTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
    _bus = widget.busId == null
        ? null
        : TransitRepository.instance.busById(widget.busId!);
    if (widget.busId != null) {
      if (SupabaseService.isInitialized) {
        _loadingGps = true;
        _subscription = _gps
            .watchBus(widget.busId!)
            .listen(
              _acceptBusFix,
              onError: (Object error) {
                if (mounted) {
                  setState(() => _gpsError = 'GPS feed unavailable: $error');
                }
              },
            );
        unawaited(_loadLastBusFix(widget.busId!));
      } else {
        _gpsError = 'OFFLINE · Supabase is not configured.';
      }
    }
    _loadStopMarkers();
  }

  void _acceptBusFix(GpsFix fix) {
    if (!fix.hasValidCoordinates || !mounted) return;
    setState(() {
      if (_fix == null || !fix.recordedAt.isBefore(_fix!.recordedAt)) {
        _fix = fix;
      }
      _loadingGps = false;
      _lastLocationLoaded = true;
      _gpsError = null;
    });
  }

  Future<void> _loadLastBusFix(String busId) async {
    try {
      final fix = await _gps.getLastLocation(busId);
      if (fix != null) _acceptBusFix(fix);
    } catch (error) {
      if (mounted) {
        setState(() => _gpsError = 'Could not load bus location: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingGps = false;
          _lastLocationLoaded = true;
        });
      }
    }
  }

  Future<void> _loadStopMarkers() async {
    if (!SupabaseService.isInitialized) return;
    try {
      final rows = await SupabaseService.client
          .from('stops')
          .select('name,latitude,longitude')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);
      for (final row in rows) {
        final lat = row['latitude'];
        final lon = row['longitude'];
        if (lat is num &&
            lon is num &&
            lat.isFinite &&
            lon.isFinite &&
            lat >= -90 &&
            lat <= 90 &&
            lon >= -180 &&
            lon <= 180) {
          _stopMarkers.add(
            Marker(
              point: LatLng(lat.toDouble(), lon.toDouble()),
              width: 38,
              height: 46,
              child: Tooltip(
                message: row['name']?.toString() ?? 'Stop',
                child: const Icon(
                  Icons.location_on,
                  color: Colors.indigo,
                  size: 34,
                ),
              ),
            ),
          );
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      /* No public stop coordinates means no stop markers. */
    }
  }

  Future<void> _showCurrentLocation() async {
    setState(() {
      _locationBusy = true;
      _gpsError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on device location services and try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw StateError('Location permission was not granted.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError('Enable location permission in system settings.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude < -90 ||
          point.latitude > 90 ||
          point.longitude < -180 ||
          point.longitude > 180) {
        throw StateError('The device returned invalid coordinates.');
      }
      if (mounted) {
        setState(() => _passengerLocation = point);
        _map.move(point, 15);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _gpsError = 'Current location unavailable: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current location unavailable: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  @override
  void dispose() {
    _ageTimer?.cancel();
    _subscription?.cancel();
    _gps.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bus map'),
      actions: [
        IconButton(
          tooltip: 'Zoom in',
          onPressed: () => _map.move(_map.camera.center, _map.camera.zoom + 1),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Zoom out',
          onPressed: () => _map.move(_map.camera.center, _map.camera.zoom - 1),
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          tooltip: 'Show my current location',
          onPressed: _locationBusy ? null : _showCurrentLocation,
          icon: _locationBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    ),
    body: Column(
      children: [
        if (_bus != null || widget.busId != null)
          ListTile(
            title: Text(
              '${_bus?.identifier ?? widget.busId} · ${_bus?.from ?? widget.from} → ${_bus?.to ?? widget.to}',
            ),
            subtitle: Text(
              _fix == null
                  ? _busLocationStatus
                  : _isLive
                  ? 'LIVE GPS · updated ${_fix!.recordedAt.toLocal()}'
                  : 'OFFLINE / STALE · last known ${_fix!.recordedAt.toLocal()}',
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: const MapOptions(
              initialCenter: _center,
              initialZoom: 10,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: 'com.goabusconnect.goabusconnect',
              ),
              if (_stopMarkers.isNotEmpty) MarkerLayer(markers: _stopMarkers),
              if (_fix?.hasValidCoordinates == true)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_fix!.latitude, _fix!.longitude),
                      width: 52,
                      height: 52,
                      child: const Icon(
                        Icons.directions_bus_filled,
                        color: Colors.teal,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              if (_passengerLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _passengerLocation!,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Text(
            _fix == null
                ? '$_busLocationStatus Map tiles need an internet connection. No bus marker or route geometry is fabricated.'
                : '${_isLive ? 'LIVE GPS' : 'OFFLINE · last known GPS'} · ${_fix!.recordedAt.toLocal()} · ${DateTime.now().difference(_fix!.recordedAt.toLocal()).inSeconds}s old · ±${_fix!.accuracyMeters.toStringAsFixed(0)} m',
          ),
        ),
      ],
    ),
  );

  String get _busLocationStatus {
    if (widget.busId == null) return 'No bus selected · no bus GPS marker.';
    if (!SupabaseService.isInitialized) {
      return 'OFFLINE · Supabase is not connected.';
    }
    if (_loadingGps) return 'LOADING · Checking for the latest bus location…';
    if (!_lastLocationLoaded) return 'LOADING · Waiting for a GPS location…';
    if (_fix == null) {
      return _gpsError ?? 'NO LOCATION · This bus has not reported GPS.';
    }
    return 'OFFLINE · Last known bus location is unavailable.';
  }

  bool get _isLive {
    if (_fix == null || !_fix!.hasValidCoordinates || !_fix!.isActive) {
      return false;
    }
    final age = DateTime.now().toUtc().difference(_fix!.recordedAt.toUtc());
    return !age.isNegative && age <= const Duration(seconds: 90);
  }
}
