import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/supabase_service.dart';

import '../data/transit_repository.dart';
import '../domain/transit_models.dart';

class DemoResultsScreen extends StatefulWidget {
  const DemoResultsScreen({
    super.key,
    required this.from,
    required this.to,
    this.date = '',
  });
  final String from, to;
  final String date;
  @override
  State<DemoResultsScreen> createState() => _DemoResultsScreenState();
}

class _DemoResultsScreenState extends State<DemoResultsScreen> {
  bool government = true, private = true;
  String departure = 'Any time';
  late Future<List<BusService>> _results;
  @override
  void initState() {
    super.initState();
    _results = _load();
  }

  @override
  void didUpdateWidget(covariant DemoResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from ||
        oldWidget.to != widget.to ||
        oldWidget.date != widget.date) {
      _results = _load();
    }
  }

  Future<List<BusService>> _load() => TransitRepository.instance.searchServices(
    widget.from,
    widget.to,
    DateTime.tryParse(widget.date) ?? DateTime.now(),
  );
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BusService>>(
      future: _results,
      builder: (context, snapshot) {
        var matches = (snapshot.data ?? <BusService>[])
            .where(
              (b) =>
                  b.ownership == BusOwnership.government ? government : private,
            )
            .toList();
        if (departure == 'Morning') {
          matches = matches
              .where(
                (b) =>
                    b.departure != null &&
                    int.parse(b.departure!.substring(0, 2)) < 12,
              )
              .toList();
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Journey options')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${widget.from} → ${widget.to}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Wrap(
                spacing: 6,
                children: [
                  FilterChip(
                    label: const Text('Government'),
                    selected: government,
                    onSelected: (v) => setState(() => government = v),
                  ),
                  FilterChip(
                    label: const Text('Private'),
                    selected: private,
                    onSelected: (v) => setState(() => private = v),
                  ),
                  DropdownButton(
                    value: departure,
                    items: ['Any time', 'Morning']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => departure = v ?? departure),
                  ),
                ],
              ),
              Card(
                child: ListTile(
                  title: Text(
                    TransitRepository.instance.lastSearchUsedDemoFallback
                        ? 'DEMO FALLBACK · UNVERIFIED'
                        : 'SOURCE-LABELLED SCHEDULE DATA',
                  ),
                  subtitle: Text(
                    'Date: ${widget.date.isEmpty ? 'today' : widget.date}',
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (snapshot.hasError)
                const Text(
                  'Unable to load schedule data. Showing local demo records.',
                ),
              if (snapshot.connectionState == ConnectionState.done &&
                  matches.isEmpty)
                const Text('No service matches this journey and date.'),
              for (final bus in matches)
                Card(
                  child: ListTile(
                    title: Text('${bus.operator} · ${bus.identifier}'),
                    subtitle: Text(
                      '${bus.ownership.name} · ${bus.from} → ${bus.to}\n${bus.departure ?? 'Time unavailable'} – ${bus.arrival ?? 'Time unavailable'} · ${bus.fare == null ? 'Fare unavailable' : '₹${bus.fare}'}\n${bus.stops.length} stops · ${bus.source} · ${bus.verification.name}',
                    ),
                    isThreeLine: true,
                    onTap: () => context.push(
                      Uri(
                        path: '/bus-details',
                        queryParameters: {
                          'id': bus.id,
                          'from': widget.from,
                          'to': widget.to,
                          'date': widget.date,
                        },
                      ).toString(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class DemoBusDetailsScreen extends StatelessWidget {
  const DemoBusDetailsScreen({
    super.key,
    required this.id,
    this.from = '',
    this.to = '',
    this.date = '',
  });
  final String id, from, to, date;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusService?>(
      future: TransitRepository.instance.serviceById(
        id,
        from: from,
        to: to,
        date: DateTime.tryParse(date),
      ),
      builder: (context, snapshot) {
        final bus = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (bus == null) {
          return const Scaffold(
            body: Center(child: Text('Bus not found or unavailable')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(bus.identifier)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Chip(label: Text('UNVERIFIED DEMO')),
              Text(bus.operator),
              Text('${bus.from} → ${bus.to}'),
              Text(
                'Departure ${bus.departure ?? 'unavailable'} · Arrival ${bus.arrival ?? 'unavailable'}',
              ),
              Text(
                'Fare ${bus.fare ?? 'unavailable'} · ${bus.stops.length} stops',
              ),
              for (final stop in bus.stops)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(stop),
                ),
              const ListTile(
                leading: Icon(Icons.gps_off),
                title: Text('Tracking unavailable: no GPS feed'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  Uri(
                    path: '/tracking',
                    queryParameters: {
                      'busId': bus.id,
                      'from': bus.from,
                      'to': bus.to,
                    },
                  ).toString(),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open live map status'),
              ),
              FilledButton(
                onPressed: () => context.push('/reports?busId=${bus.id}'),
                child: const Text('Report an issue'),
              ),
              OutlinedButton(
                onPressed: () {
                  TransitRepository.instance.toggleSaved(bus.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved on this device')),
                  );
                },
                child: const Text('Save journey'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PassengerComplaintScreen extends StatefulWidget {
  const PassengerComplaintScreen({super.key, this.busId = ''});
  final String busId;
  @override
  State<PassengerComplaintScreen> createState() =>
      _PassengerComplaintScreenState();
}

class _PassengerComplaintScreenState extends State<PassengerComplaintScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  String? _busId;
  String _person = 'Driver';
  String _category = 'Safety';
  DateTime? _occurredAt;
  List<BusService> _buses = TransitRepository.buses;
  final Map<String, String> _organizationForBus = {};
  @override
  void initState() {
    super.initState();
    _busId = widget.busId.isEmpty
        ? TransitRepository.buses.first.id
        : widget.busId;
    _loadCloudBuses();
  }

  Future<void> _loadCloudBuses() async {
    if (!SupabaseService.isInitialized) return;
    try {
      final rows = await SupabaseService.client
          .from('buses')
          .select('id,identifier,operator_name,ownership,organization_id')
          .eq('active', true);
      final buses = <BusService>[];
      for (final row in rows) {
        final id = row['id'] as String;
        final org = row['organization_id'] as String;
        _organizationForBus[id] = org;
        buses.add(
          BusService(
            id: id,
            identifier: row['identifier'].toString(),
            operator: row['operator_name'].toString(),
            ownership: row['ownership'] == 'government'
                ? BusOwnership.government
                : BusOwnership.private,
            from: 'Schedule',
            to: 'details',
            stops: const [],
            source: 'Supabase bus registry',
            verification: VerificationStatus.unverifiedDemo,
          ),
        );
      }
      if (mounted && buses.isNotEmpty) {
        setState(() {
          _buses = buses;
          _busId =
              widget.busId.isNotEmpty && buses.any((b) => b.id == widget.busId)
              ? widget.busId
              : buses.first.id;
        });
      }
    } catch (_) {
      /* Keep local complaint demo available offline. */
    }
  }

  Future<void> _pickOccurredAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt ?? DateTime.now()),
    );
    if (time != null) {
      setState(
        () => _occurredAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _submitComplaint() async {
    if (!_form.currentState!.validate() || _busId == null) return;
    final bus = _buses.firstWhere((b) => b.id == _busId);
    final client = SupabaseService.isInitialized
        ? SupabaseService.client
        : null;
    final user = client?.auth.currentUser;
    final orgId = _organizationForBus[_busId];
    if (user != null && orgId != null) {
      try {
        await client!.from('complaints').insert({
          'passenger_id': user.id,
          'organization_id': orgId,
          'bus_id': _busId,
          'subject_type': _person == 'Driver'
              ? 'driver'
              : _person == 'Conductor'
              ? 'conductor'
              : 'bus',
          'category': _category,
          'description': _description.text.trim(),
          'occurred_at': _occurredAt?.toUtc().toIso8601String(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Private complaint was not submitted: $e')),
          );
        }
        return;
      }
    } else {
      if (user != null && orgId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This bus is not available for private complaint submission.',
            ),
          ),
        );
        return;
      }
      TransitRepository.instance.addComplaint(
        PassengerComplaint(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          busId: bus.id,
          busLabel: bus.identifier,
          personType: _person,
          category: _category,
          description: _description.text.trim(),
          submittedAt: DateTime.now(),
          occurredAt: _occurredAt,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user != null
              ? 'Complaint submitted privately. Status: submitted.'
              : 'Demo complaint saved on this device. Status: submitted.',
        ),
      ),
    );
    context.pop();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report a concern')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Private cloud submission requires sign-in. Otherwise this is stored locally on this device and is not visible to an owner.',
          ),
          DropdownButtonFormField<String>(
            initialValue: _busId,
            decoration: const InputDecoration(labelText: 'Bus'),
            items: [
              for (final b in _buses)
                DropdownMenuItem(value: b.id, child: Text(b.identifier)),
            ],
            onChanged: (v) => setState(() => _busId = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: _person,
            decoration: const InputDecoration(labelText: 'Concern relates to'),
            items: [
              'Driver',
              'Conductor',
              'Bus/service',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _person = v ?? _person),
          ),
          OutlinedButton.icon(
            onPressed: _pickOccurredAt,
            icon: const Icon(Icons.event),
            label: Text(
              _occurredAt == null
                  ? 'Add incident date and time (optional)'
                  : _occurredAt!.toLocal().toString(),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              'Safety',
              'Conduct',
              'Delay',
              'Overcrowding',
              'Accessibility',
              'Other',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          TextFormField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Describe the issue'),
            validator: (v) => v == null || v.trim().length < 5
                ? 'Please add at least 5 characters.'
                : null,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitComplaint,
            child: const Text('Save demo complaint'),
          ),
        ],
      ),
    ),
  );
}
