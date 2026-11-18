import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/gps_service.dart';
import '../../core/services/supabase_service.dart';
import '../transit/data/transit_repository.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});
  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _gps = DeviceGPSService();
  StreamSubscription<GpsFix>? _sub;
  GpsFix? _fix;
  String _bus = TransitRepository.buses.first.id;
  String? _error;
  bool _tracking = false, _busy = false, _loggedIn = false;
  List<MapEntry<String, String>> _assignedBuses = [];
  @override
  void dispose() {
    _sub?.cancel();
    _gps.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!SupabaseService.isInitialized) {
      setState(() {
        _loggedIn = true;
        _error = 'DEMO OFFLINE: GPS will be read from this device, but nothing is uploaded.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = SupabaseService.client;
      await client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', client.auth.currentUser!.id)
          .maybeSingle();
      if (profile?['role'] != 'operator') {
        throw StateError('This account does not have the operator role.');
      }
      final rows = await client
          .from('bus_assignments')
          .select('bus_id,buses(identifier)')
          .eq('operator_id', client.auth.currentUser!.id);
      _assignedBuses = [
        for (final row in rows)
          MapEntry(
            row['bus_id'] as String,
            (row['buses'] as Map)['identifier'] as String,
          ),
      ];
      if (_assignedBuses.isEmpty) {
        throw StateError('No bus is assigned to this operator.');
      }
      setState(() {
        _bus = _assignedBuses.first.key;
        _loggedIn = true;
      });
    } catch (e) {
      setState(() => _error = 'Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _gps.start(_bus);
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      ).then(
        (p) => setState(
          () => _fix = GpsFix(
            latitude: p.latitude,
            longitude: p.longitude,
            accuracyMeters: p.accuracy,
            recordedAt: p.timestamp.toUtc(),
            busId: _bus,
          ),
        ),
      );
      _sub = _gps.fixes.listen((fix) {
        if (mounted) setState(() => _fix = fix);
      });
      setState(() {
        _tracking = true;
        _error = _gps.lastError;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    await _gps.stop();
    await _sub?.cancel();
    setState(() {
      _tracking = false;
      _error = 'OFFLINE: tracking stopped';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('GPS operator'),
      actions: [
        IconButton(
          tooltip: 'Role chooser',
          onPressed: () => context.push('/roles'),
          icon: const Icon(Icons.switch_account),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Chip(
          avatar: Icon(Icons.sensors),
          label: Text('DEVICE GPS · NO SIMULATED LOCATION'),
        ),
        if (!_loggedIn) ...[
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Operator email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: Text(
              SupabaseService.isInitialized
                  ? 'Sign in as operator'
                  : 'Continue in offline demo',
            ),
          ),
        ],
        if (_loggedIn) ...[
          DropdownButtonFormField<String>(
            initialValue: _bus,
            decoration: const InputDecoration(labelText: 'Assigned bus'),
            items: _assignedBuses.isEmpty
                ? [
                    for (final b in TransitRepository.buses)
                      DropdownMenuItem(
                        value: b.id,
                        child: Text('${b.identifier} · DEMO'),
                      ),
                  ]
                : [
                    for (final b in _assignedBuses)
                      DropdownMenuItem(value: b.key, child: Text(b.value)),
                  ],
            onChanged: _tracking
                ? null
                : (v) => setState(() => _bus = v ?? _bus),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                _gps.isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: _gps.isConnected ? Colors.green : Colors.orange,
              ),
              title: Text(
                _gps.isConnected
                    ? 'LIVE GPS · uploaded'
                    : _tracking
                    ? 'GPS ACTIVE · OFFLINE'
                    : 'OFFLINE · not tracking',
              ),
              subtitle: Text(
                _error ?? _gps.lastError ?? 'Cloud status reflects the latest publish; stale data must not be shown as live.',
              ),
            ),
          ),
          if (_fix != null)
            Card(
              child: ListTile(
                title: Text(
                  'Latitude  ${_fix!.latitude.toStringAsFixed(6)}\nLongitude ${_fix!.longitude.toStringAsFixed(6)}',
                ),
                subtitle: Text(
                  'Accuracy ±${_fix!.accuracyMeters.toStringAsFixed(0)} m · ${_fix!.recordedAt.toLocal()}',
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _tracking || _busy ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start tracking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _tracking ? _stop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop tracking'),
                ),
              ),
            ],
          ),
          const Text(
            'Cloud publishing is only available after operator sign-in and server-side bus assignment. Demo mode reads real device GPS only while this screen is active.',
          ),
        ],
        if (_error != null && !_loggedIn)
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    ),
  );
}
