import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

@immutable
class GpsFix {
  const GpsFix({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.accuracyMeters,
    this.busId,
    this.isActive = true,
  });
  final double latitude, longitude, accuracyMeters;
  final DateTime recordedAt;
  final String? busId;
  final bool isActive;
  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

abstract interface class GPSService {
  bool get isConnected;
  DateTime? get lastUpdated;
  Future<void> start(String busId);
  Future<void> stop();
  Stream<GpsFix> get fixes;
  Stream<GpsFix> watchBus(String busId);
}

/// Uses actual device location. No generated coordinates are ever emitted.
class DeviceGPSService implements GPSService {
  DeviceGPSService({this._client});
  final SupabaseClient? _client;
  final _fixes = StreamController<GpsFix>.broadcast();
  StreamSubscription<Position>? _positionSub;
  RealtimeChannel? _channel;
  bool _connected = false;
  String? _busId;
  DateTime? _lastUpdated;
  String? lastError;
  @override
  bool get isConnected => _connected;
  @override
  DateTime? get lastUpdated => _lastUpdated;
  @override
  Stream<GpsFix> get fixes => _fixes.stream;

  /// Reads the last stored fix so the map can show its age while Realtime
  /// waits for the next update. Invalid coordinates are discarded.
  Future<GpsFix?> getLastLocation(String busId) async {
    final client =
        _client ??
        (SupabaseService.isInitialized ? SupabaseService.client : null);
    if (client == null) return null;
    final row = await client
        .from('gps_locations')
        .select(
          'bus_id,latitude,longitude,accuracy_meters,recorded_at,is_active',
        )
        .eq('bus_id', busId)
        .maybeSingle();
    if (row == null) return null;
    final lat = row['latitude'];
    final lon = row['longitude'];
    final time = row['recorded_at'];
    if (lat is! num || lon is! num || time is! String) return null;
    final recordedAt = DateTime.tryParse(time);
    if (recordedAt == null) return null;
    final fix = GpsFix(
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      accuracyMeters: (row['accuracy_meters'] as num?)?.toDouble() ?? 0,
      recordedAt: recordedAt.toUtc(),
      busId: busId,
      isActive: row['is_active'] == true,
    );
    return fix.hasValidCoordinates ? fix : null;
  }

  @override
  Future<void> start(String busId) async {
    await stop();
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Device location services are off.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted.');
    }
    _busId = busId;
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
      timeLimit: Duration(seconds: 30),
    );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (p) => unawaited(_publish(p)),
          onError: (Object e) {
            lastError = e.toString();
            _connected = false;
          },
        );
  }

  Future<void> _publish(Position p) async {
    final fix = GpsFix(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracyMeters: p.accuracy,
      recordedAt: p.timestamp.toUtc(),
      busId: _busId,
    );
    _fixes.add(fix);
    _lastUpdated = fix.recordedAt;
    final client =
        _client ??
        (SupabaseService.isInitialized ? SupabaseService.client : null);
    if (client == null) {
      lastError = 'OFFLINE: Supabase is not configured';
      _connected = false;
      return;
    }
    try {
      await client.from('gps_locations').upsert({
        'bus_id': _busId,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'accuracy_meters': p.accuracy,
        'recorded_at': fix.recordedAt.toIso8601String(),
        'operator_id': client.auth.currentUser?.id,
        'is_active': true,
      }, onConflict: 'bus_id');
      _connected = true;
      lastError = null;
    } catch (e) {
      _connected = false;
      lastError = 'OFFLINE: $e';
    }
    // Notify the operator UI after the network result changes.
    _fixes.add(fix);
  }

  @override
  Stream<GpsFix> watchBus(String busId) {
    final client =
        _client ??
        (SupabaseService.isInitialized ? SupabaseService.client : null);
    if (client == null) return const Stream.empty();
    _channel?.unsubscribe();
    final controller = StreamController<GpsFix>();
    _channel = client
        .channel('gps:$busId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'gps_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'bus_id',
            value: busId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final lat = row['latitude'];
            final lon = row['longitude'];
            final time = row['recorded_at'];
            final recordedAt = time is String ? DateTime.tryParse(time) : null;
            if (lat is num && lon is num && recordedAt != null) {
              final fix = GpsFix(
                latitude: lat.toDouble(),
                longitude: lon.toDouble(),
                accuracyMeters:
                    (row['accuracy_meters'] as num?)?.toDouble() ?? 0,
                recordedAt: recordedAt.toUtc(),
                busId: busId,
                isActive: row['is_active'] == true,
              );
              if (fix.hasValidCoordinates) controller.add(fix);
            }
          },
        )
        .subscribe();
    controller.onCancel = () => _channel?.unsubscribe();
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    final bus = _busId;
    final client =
        _client ??
        (SupabaseService.isInitialized ? SupabaseService.client : null);
    if (bus != null && client != null && client.auth.currentUser != null) {
      try {
        await client
            .from('gps_locations')
            .update({'is_active': false})
            .eq('bus_id', bus)
            .eq('operator_id', client.auth.currentUser!.id);
      } catch (e) {
        lastError = 'OFFLINE: could not mark GPS inactive ($e)';
      }
    }
    _connected = false;
    _busId = null;
  }

  Future<void> dispose() async {
    await stop();
    await _channel?.unsubscribe();
    await _fixes.close();
  }
}

class UnavailableGPSService implements GPSService {
  const UnavailableGPSService();
  @override
  bool get isConnected => false;
  @override
  DateTime? get lastUpdated => null;
  @override
  Future<void> start(String busId) async =>
      throw UnsupportedError('No device GPS provider is configured.');
  @override
  Future<void> stop() async {}
  @override
  Stream<GpsFix> get fixes => const Stream.empty();
  @override
  Stream<GpsFix> watchBus(String busId) => const Stream.empty();
}
