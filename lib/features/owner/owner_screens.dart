import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose workspace')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Passenger services are available in the Home tabs. Operator and owner tools require assigned Supabase roles for cloud data.',
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Passenger'),
            subtitle: const Text('Search, journeys and demo complaints'),
            onTap: () => context.go('/home'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: const Text('GPS operator'),
            subtitle: const Text('Actual phone GPS · offline demo available'),
            onTap: () => context.push('/operator'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Bus owner / administrator'),
            subtitle: Text(
              SupabaseService.isConfigured
                  ? 'Sign in to your private organization'
                  : 'DEMO DATA · configuration required for private records',
            ),
            onTap: () => context.push('/owner'),
          ),
        ),
      ],
    ),
  );
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});
  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  String? _message;
  bool _signedIn = false, _busy = false;
  Map<String, int> _counts = {};
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!SupabaseService.isInitialized) {
      setState(
        () => _message = 'DEMO DATA: sample dashboard only. Configure Supabase and sign in to access private owner records.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final c = SupabaseService.client;
      await c.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final profile = await c
          .from('profiles')
          .select('role')
          .eq('id', c.auth.currentUser!.id)
          .maybeSingle();
      if (profile?['role'] != 'owner' && profile?['role'] != 'admin') {
        throw StateError('This account is not assigned the owner role.');
      }
      setState(() => _signedIn = true);
      await _loadCounts();
    } catch (e) {
      setState(() => _message = 'Owner sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadCounts() async {
    try {
      final c = SupabaseService.client;
      final org = await c
          .from('organizations')
          .select('id')
          .eq('owner_user_id', c.auth.currentUser!.id)
          .limit(1)
          .maybeSingle();
      if (org == null) {
        setState(() => _message = 'No organization is assigned to this owner.');
        return;
      }
      final id = org['id'];
      final buses = await c
          .from('buses')
          .select('id,active')
          .eq('organization_id', id);
      final drivers = await c
          .from('drivers')
          .select('id')
          .eq('organization_id', id);
      final conductors = await c
          .from('conductors')
          .select('id')
          .eq('organization_id', id);
      final complaints = await c
          .from('complaints')
          .select('id')
          .eq('organization_id', id);
      if (mounted) {
        setState(
          () => _counts = {
            'Buses': buses.length,
            'Active buses': buses.where((b) => b['active'] == true).length,
            'Drivers': drivers.length,
            'Conductors': conductors.length,
            'Complaints': complaints.length,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Could not load organization metrics: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Owner dashboard')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Chip(label: Text('DEMO SAMPLE · NOT LIVE DATA')),
            if (!SupabaseService.isConfigured) ...[
              const ListTile(
                title: Text('Total buses · sample'),
                trailing: Text('4 · DEMO'),
              ),
              const ListTile(
                title: Text('Active buses · sample'),
                trailing: Text('2 · DEMO'),
              ),
              const ListTile(
                title: Text('Drivers · sample'),
                trailing: Text('3 · DEMO'),
              ),
              const ListTile(
                title: Text('Conductors · sample'),
                trailing: Text('3 · DEMO'),
              ),
              const ListTile(
                title: Text('Routes · sample'),
                trailing: Text('3 · DEMO'),
              ),
              const Text(
                'These illustrative counts are demo samples, not live or official records. Connect Supabase to load your private organization data.',
              ),
            ],
            if (SupabaseService.isConfigured) ...[
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Owner email'),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              FilledButton(
                onPressed: _busy ? null : _login,
                child: const Text('Sign in securely'),
              ),
            ],
            if (_message != null) Text(_message!),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner dashboard'),
        actions: [
          IconButton(
            onPressed: () => SupabaseService.client.auth.signOut().then(
              (_) => setState(() => _signedIn = false),
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Organization records are protected by Supabase RLS.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final metric in _counts.entries)
            ListTile(
              title: Text(metric.key),
              trailing: Text('${metric.value}'),
            ),
          if (_message != null) Text(_message!),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gps_fixed),
              title: const Text('Live GPS monitoring'),
              onTap: () => context.push('/owner/live-gps'),
            ),
          ),
          for (final section in {
            'Buses': 'buses',
            'Drivers': 'drivers',
            'Conductors': 'conductors',
            'Routes and timings': 'routes',
            'Stops': 'stops',
            'Trips and published times': 'trips',
            'Complaint inbox': 'complaints',
          }.entries)
            Card(
              child: ListTile(
                title: Text(section.key),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/owner/manage/${section.value}'),
              ),
            ),
        ],
      ),
    );
  }
}

class OwnerManagerScreen extends StatefulWidget {
  const OwnerManagerScreen({super.key, required this.table});
  final String table;
  @override
  State<OwnerManagerScreen> createState() => _OwnerManagerScreenState();
}

class OwnerGpsMonitorScreen extends StatefulWidget {
  const OwnerGpsMonitorScreen({super.key});
  @override
  State<OwnerGpsMonitorScreen> createState() => _OwnerGpsMonitorScreenState();
}

class _OwnerGpsMonitorScreenState extends State<OwnerGpsMonitorScreen> {
  List<Map<String, dynamic>> _locations = [];
  String? _error;
  bool _loading = true;
  dynamic _channel;
  @override
  void initState() {
    super.initState();
    _load();
    if (SupabaseService.isInitialized) {
      _channel = SupabaseService.client
          .channel('owner-gps-monitor')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'gps_locations',
            callback: (_) => _load(),
          )
          .subscribe();
    }
  }

  Future<void> _load() async {
    if (!SupabaseService.isInitialized) {
      setState(() => _loading = false);
      return;
    }
    try {
      final c = SupabaseService.client;
      final org = await c
          .from('organizations')
          .select('id')
          .eq('owner_user_id', c.auth.currentUser!.id)
          .limit(1)
          .maybeSingle();
      if (org == null) {
        setState(() => _error = 'No owner organization is assigned.');
        return;
      }
      final buses = await c
          .from('buses')
          .select('id')
          .eq('organization_id', org['id']);
      final ids = buses.map((b) => (b['id'] as String)).toList();
      final rows = ids.isEmpty
          ? []
          : await c.from('gps_locations').select().inFilter('bus_id', ids);
      if (mounted) {
        setState(() => _locations = List<Map<String, dynamic>>.from(rows));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'GPS data unavailable: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live GPS monitor')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text(_error!))
        : _locations.isEmpty
        ? const Center(child: Text('OFFLINE · No bus has published GPS.'))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              children: [
                for (final row in _locations)
                  Builder(
                    builder: (context) {
                      final time = DateTime.tryParse(
                        row['recorded_at']?.toString() ?? '',
                      )?.toLocal();
                      final age = time == null
                          ? null
                          : DateTime.now().difference(time);
                      final live =
                          row['is_active'] == true &&
                          age != null &&
                          age <= const Duration(seconds: 90);
                      return ListTile(
                        leading: Icon(
                          live ? Icons.gps_fixed : Icons.gps_off,
                          color: live ? Colors.green : Colors.orange,
                        ),
                        title: Text(live ? 'LIVE GPS' : 'STALE / OFFLINE'),
                        subtitle: Text(
                          'Bus ${row['bus_id']} · ${row['latitude']}, ${row['longitude']}\nLast update ${time ?? 'unknown'} · ${age?.inSeconds ?? '?'}s old',
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
  );
}

class _OwnerManagerScreenState extends State<OwnerManagerScreen> {
  bool _busy = true;
  String? _org;
  List<Map<String, dynamic>> _rows = [];
  String get _label => widget.table;
  static const _allowedTables = {
    'buses',
    'drivers',
    'conductors',
    'routes',
    'trips',
    'stop_times',
    'stops',
    'complaints',
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_allowedTables.contains(_label)) {
      setState(() => _busy = false);
      return;
    }
    if (!SupabaseService.isInitialized) {
      setState(() => _busy = false);
      return;
    }
    try {
      final c = SupabaseService.client;
      final org = await c
          .from('organizations')
          .select('id')
          .eq('owner_user_id', c.auth.currentUser!.id)
          .limit(1)
          .maybeSingle();
      _org = org?['id'] as String?;
      if (_org != null) {
        final data = await c
            .from(_label)
            .select()
            .eq('organization_id', _org!)
            .limit(100);
        _rows = List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setComplaintStatus(Map<String, dynamic> row) async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update complaint status'),
        children: [
          for (final value in [
            'submitted',
            'reviewing',
            'resolved',
            'dismissed',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Text(value),
            ),
        ],
      ),
    );
    if (status == null) return;
    try {
      await SupabaseService.client
          .from('complaints')
          .update({'status': status})
          .eq('id', row['id']);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status update rejected: $e')));
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(
      text:
          (row?['name'] ??
                  row?['full_name'] ??
                  row?['identifier'] ??
                  row?['stop_sequence'] ??
                  '')
              .toString(),
    );
    final secondary = TextEditingController(
      text:
          (row?['source_label'] ??
                  row?['operator_name'] ??
                  row?['phone'] ??
                  row?['route_id'] ??
                  '')
              .toString(),
    );
    final third = TextEditingController(
      text:
          (row?['destination_label'] ?? row?['ownership'] ?? row?['fare'] ?? '')
              .toString(),
    );
    final fourth = TextEditingController(
      text: (row?['departure_time'] ?? '').toString(),
    );
    final fifth = TextEditingController(
      text: (row?['arrival_time'] ?? '').toString(),
    );
    final sixth = TextEditingController(text: (row?['fare'] ?? '').toString());
    final seventh = TextEditingController(text: (row?['area'] ?? '').toString());
    final eighth = TextEditingController(text: (row?['latitude'] ?? '').toString());
    final ninth = TextEditingController(text: (row?['longitude'] ?? '').toString());
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row == null ? 'Add $_label' : 'Edit $_label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: _label == 'drivers' || _label == 'conductors'
                    ? 'Full name'
                    : _label == 'buses'
                    ? 'Bus identifier'
                    : _label == 'stop_times'
                    ? 'Stop sequence number'
                    : 'Name',
              ),
            ),
            if (_label == 'routes' ||
                _label == 'buses' ||
                _label == 'drivers' ||
                _label == 'conductors' ||
                _label == 'trips' ||
                _label == 'stop_times')
              TextField(
                controller: secondary,
                decoration: InputDecoration(
                  labelText: _label == 'routes'
                      ? 'Source label'
                      : _label == 'buses'
                      ? 'Operator name'
                      : _label == 'trips'
                      ? 'Bus UUID'
                      : _label == 'stop_times'
                      ? 'Trip UUID'
                      : 'Phone (optional)',
                ),
              ),
            if (_label == 'routes' ||
                _label == 'buses' ||
                _label == 'trips' ||
                _label == 'stop_times')
              TextField(
                controller: third,
                decoration: InputDecoration(
                  labelText: _label == 'routes'
                      ? 'Destination label'
                      : _label == 'buses'
                      ? 'Ownership: government or private'
                      : _label == 'trips'
                      ? 'Route UUID'
                      : 'Stop UUID',
                ),
              ),
            if (_label == 'trips' || _label == 'stop_times') ...[
              TextField(
                controller: fourth,
                decoration: const InputDecoration(
                  labelText: 'Departure time (HH:MM)',
                ),
              ),
              TextField(
                controller: fifth,
                decoration: const InputDecoration(
                  labelText: 'Arrival time (HH:MM)',
                ),
              ),
              TextField(
                controller: sixth,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fare (optional)'),
              ),
            ],
            if (_label == 'trips' || _label == 'stop_times')
              const Text(
                'Use UUIDs from your organization’s bus and route records. Schedule status starts as UNVERIFIED.',
              ),
            if (_label == 'stops') ...[
              TextField(controller: secondary, decoration: const InputDecoration(labelText: 'Area (optional)')),
              TextField(controller: eighth, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude (optional)')),
              TextField(controller: ninth, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude (optional)')),
              const Text('Coordinates must come from a verified stop source. Empty coordinates are allowed.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, [
              name.text.trim(),
              secondary.text.trim(),
              third.text.trim(),
              fourth.text.trim(),
              fifth.text.trim(),
              sixth.text.trim(),
              seventh.text.trim(),
              eighth.text.trim(),
              ninth.text.trim(),
            ]),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.first.isEmpty || _org == null) return;
    final field = _label == 'drivers' || _label == 'conductors'
        ? 'full_name'
        : _label == 'buses'
        ? 'identifier'
        : _label == 'trips' || _label == 'stop_times'
        ? null
        : 'name';
    final data = <String, dynamic>{'organization_id': _org};
    if (field != null) data[field] = result.first;
    if (_label == 'routes') {
      data['source_label'] = result[1];
      data['destination_label'] = result[2];
    } else if (_label == 'buses') {
      data['operator_name'] = result[1];
      data['ownership'] = result[2].toLowerCase();
    } else if (_label == 'drivers' || _label == 'conductors') {
      data['phone'] = result[1].isEmpty ? null : result[1];
    } else if (_label == 'trips') {
      data['bus_id'] = result[1];
      data['route_id'] = result[2];
      data['service_date'] = DateTime.now().toIso8601String().substring(0, 10);
      data['data_source'] = 'Owner-entered schedule';
      data['verification_status'] = 'unverified';
      data['departure_time'] = result[3].isEmpty ? null : result[3];
      data['arrival_time'] = result[4].isEmpty ? null : result[4];
      data['fare'] = result[5].isEmpty ? null : num.tryParse(result[5]);
    } else if (_label == 'stop_times') {
      data['stop_sequence'] = int.tryParse(result[0]);
      data['trip_id'] = result[1];
      data['stop_id'] = result[2];
      data['arrival_time'] = result[3].isEmpty ? null : result[3];
      data['departure_time'] = result[4].isEmpty ? null : result[4];
    } else if (_label == 'stops') {
      data['area'] = result[1];
      data['latitude'] = result[7].isEmpty ? null : double.tryParse(result[7]);
      data['longitude'] = result[8].isEmpty ? null : double.tryParse(result[8]);
    }
    try {
      if (row == null) {
        await SupabaseService.client.from(_label).insert(data);
      } else {
        await SupabaseService.client
            .from(_label)
            .update(data)
            .eq('id', row['id']);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed (RLS may reject this role): $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_label),
      actions: [
        if (_label != 'complaints')
          IconButton(onPressed: _edit, icon: const Icon(Icons.add)),
      ],
    ),
    body: !SupabaseService.isInitialized
        ? const Center(
            child: Text('OFFLINE · private organization data unavailable'),
          )
        : _busy
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              children: [
                for (final row in _rows)
                  ListTile(
                    title: Text(
                      (row['name'] ??
                              row['category'] ??
                              row['full_name'] ??
                              row['identifier'] ??
                              row['title'] ??
                              'Record')
                          .toString(),
                    ),
                    subtitle: Text(
                      _label == 'complaints'
                          ? 'Status: ${row['status']} · Bus: ${row['bus_id']}'
                          : row['id'].toString(),
                    ),
                    onTap: () => _label == 'complaints'
                        ? _setComplaintStatus(row)
                        : _edit(row),
                    trailing: _label == 'complaints'
                        ? const Icon(Icons.verified_user_outlined)
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await SupabaseService.client
                                  .from(_label)
                                  .delete()
                                  .eq('id', row['id']);
                              await _load();
                            },
                          ),
                  ),
              ],
            ),
          ),
  );
}
