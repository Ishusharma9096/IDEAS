import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/supabase_service.dart';

import '../domain/transit_models.dart';

/// Local examples for interface development. Every service is unverified demo data.
class TransitRepository {
  TransitRepository._();
  static final instance = TransitRepository._();

  static const stops = <BusStop>[
    BusStop(id: 'panaji', name: 'Panaji KTC', area: 'Panaji'),
    BusStop(id: 'mapusa', name: 'Mapusa KTC', area: 'Mapusa'),
    BusStop(id: 'porvorim', name: 'Porvorim', area: 'North Goa'),
    BusStop(id: 'margao', name: 'Margao KTC', area: 'Margao'),
    BusStop(id: 'ponda', name: 'Ponda KTC', area: 'Ponda'),
    BusStop(id: 'vasco', name: 'Vasco KTC', area: 'Vasco da Gama'),
  ];
  static const routes = <BusRoute>[
    BusRoute(
      id: 'panaji-margao',
      name: 'Panaji – Margao',
      from: 'Panaji',
      to: 'Margao',
      stops: ['Panaji KTC', 'Porvorim', 'Ponda KTC', 'Margao KTC'],
    ),
    BusRoute(
      id: 'panaji-mapusa',
      name: 'Panaji – Mapusa',
      from: 'Panaji',
      to: 'Mapusa',
      stops: ['Panaji KTC', 'Porvorim', 'Mapusa KTC'],
    ),
    BusRoute(
      id: 'margao-vasco',
      name: 'Margao – Vasco',
      from: 'Margao',
      to: 'Vasco',
      stops: ['Margao KTC', 'Vasco KTC'],
    ),
  ];
  static const buses = <BusService>[
    BusService(
      id: 'demo-ktc-101',
      operator: 'Government Bus Operator (DEMO)',
      identifier: 'DEMO KTC-101',
      ownership: BusOwnership.government,
      from: 'Panaji',
      to: 'Margao',
      stops: ['Panaji KTC', 'Porvorim', 'Ponda KTC', 'Margao KTC'],
      departure: '08:15',
      arrival: '10:45',
      fare: 55,
      source: 'Local demo record',
      verification: VerificationStatus.unverifiedDemo,
    ),
    BusService(
      id: 'demo-ktc-204',
      operator: 'Government Bus Operator (DEMO)',
      identifier: 'DEMO KTC-204',
      ownership: BusOwnership.government,
      from: 'Panaji',
      to: 'Mapusa',
      stops: ['Panaji KTC', 'Porvorim', 'Mapusa KTC'],
      departure: '09:00',
      arrival: '09:50',
      fare: 25,
      source: 'Local demo record',
      verification: VerificationStatus.unverifiedDemo,
    ),
    BusService(
      id: 'demo-private-17',
      operator: 'Demo Private Operator',
      identifier: 'DEMO P-017',
      ownership: BusOwnership.private,
      from: 'Panaji',
      to: 'Margao',
      stops: ['Panaji KTC', 'Ponda KTC', 'Margao KTC'],
      departure: '11:30',
      arrival: '13:40',
      source: 'Local demo record',
      verification: VerificationStatus.unverifiedDemo,
    ),
    BusService(
      id: 'demo-private-22',
      operator: 'Demo Private Operator',
      identifier: 'DEMO P-022',
      ownership: BusOwnership.private,
      from: 'Margao',
      to: 'Vasco',
      stops: ['Margao KTC', 'Vasco KTC'],
      source: 'Local demo record',
      verification: VerificationStatus.unverifiedDemo,
    ),
  ];

  final _saved = <String>{};
  final _recent = <JourneySearchRecord>[];
  final _complaints = <PassengerComplaint>[];
  final Map<String, BusService> _knownBuses = {
    for (final bus in buses) bus.id: bus,
  };
  bool lastSearchUsedDemoFallback = false;
  Future<void> _store(String key, List<String> values) async {
    try {
      await (await SharedPreferences.getInstance()).setStringList(key, values);
    } catch (_) {
      /* Keep this session usable if local storage is unavailable. */
    }
  }

  Future<void> initialize() async {
    final p = await SharedPreferences.getInstance();
    _saved.addAll(p.getStringList('saved_bus_ids') ?? const []);
    for (final raw in p.getStringList('recent_journeys') ?? const []) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _recent.add(
        JourneySearchRecord(
          from: j['from'] as String,
          to: j['to'] as String,
          date: DateTime.parse(j['date'] as String),
          searchedAt: DateTime.parse(j['searchedAt'] as String),
        ),
      );
    }
    for (final raw in p.getStringList('demo_complaints') ?? const []) {
      _complaints.add(
        PassengerComplaint.fromJson(jsonDecode(raw) as Map<String, Object?>),
      );
    }
  }

  List<BusService> search(String from, String to) => buses
      .where(
        (b) =>
            b.from.toLowerCase().contains(from.toLowerCase()) &&
            b.to.toLowerCase().contains(to.toLowerCase()),
      )
      .toList();

  Future<List<BusService>> searchServices(
    String from,
    String to,
    DateTime date,
  ) async {
    if (!SupabaseService.isInitialized) {
      lastSearchUsedDemoFallback = true;
      return search(from, to);
    }
    try {
      final rows = await SupabaseService.client
          .from('trips')
          .select(
            'id,service_date,departure_time,arrival_time,fare,data_source,verification_status,buses!inner(identifier,operator_name,ownership),routes!inner(source_label,destination_label),stop_times(stop_sequence,stops(name))',
          )
          .eq('active', true)
          .eq('service_date', date.toIso8601String().substring(0, 10));
      final items = <BusService>[];
      for (final row in rows) {
        final bus = row['buses'] as Map<String, dynamic>?;
        final route = row['routes'] as Map<String, dynamic>?;
        if (bus == null || route == null) continue;
        final source = (route['source_label'] ?? '').toString();
        final destination = (route['destination_label'] ?? '').toString();
        if (!source.toLowerCase().contains(from.toLowerCase()) ||
            !destination.toLowerCase().contains(to.toLowerCase())) {
          continue;
        }
        final rawStops = (row['stop_times'] as List<dynamic>? ?? [])
          ..sort(
            (a, b) => ((a as Map)['stop_sequence'] as int).compareTo(
              ((b as Map)['stop_sequence'] as int),
            ),
          );
        final stops = rawStops
            .map(
              (v) =>
                  ((v as Map)['stops'] as Map?)?['name']?.toString() ?? 'Stop',
            )
            .toList();
        final status = row['verification_status'] == 'verified'
            ? VerificationStatus.verified
            : row['verification_status'] == 'expired'
            ? VerificationStatus.expired
            : VerificationStatus.unverifiedDemo;
        final ownership = bus['ownership'] == 'government'
            ? BusOwnership.government
            : BusOwnership.private;
        String? time(Object? value) => value?.toString().substring(0, 5);
        items.add(
          BusService(
            id: row['id'].toString(),
            operator: bus['operator_name'].toString(),
            identifier: bus['identifier'].toString(),
            ownership: ownership,
            from: source,
            to: destination,
            stops: stops,
            departure: time(row['departure_time']),
            arrival: time(row['arrival_time']),
            fare: (row['fare'] as num?)?.toDouble(),
            source: row['data_source']?.toString() ?? 'Unspecified source',
            verification: status,
          ),
        );
      }
      for (final item in items) {
        _knownBuses[item.id] = item;
      }
      lastSearchUsedDemoFallback = false;
      return items;
    } catch (_) {
      lastSearchUsedDemoFallback = true;
      return search(from, to);
    }
  }

  BusService? busById(String id) => _knownBuses[id];
  Future<BusService?> serviceById(
    String id, {
    String from = '',
    String to = '',
    DateTime? date,
  }) async {
    final local = busById(id);
    if (local != null) return local;
    final items = await searchServices(from, to, date ?? DateTime.now());
    return items.where((b) => b.id == id).firstOrNull;
  }

  BusRoute? routeById(String id) => routes.where((r) => r.id == id).firstOrNull;
  List<BusRoute> routesForStop(String stop) => routes
      .where((r) => r.stops.any((s) => s.toLowerCase() == stop.toLowerCase()))
      .toList();
  List<BusRoute> searchRoutes(String q) => routes
      .where(
        (r) => '${r.name} ${r.stops.join(' ')}'.toLowerCase().contains(
          q.toLowerCase(),
        ),
      )
      .toList();
  List<BusStop> searchStops(String q) => stops
      .where(
        (s) => '${s.name} ${s.area}'.toLowerCase().contains(q.toLowerCase()),
      )
      .toList();
  void recordSearch(String from, String to, DateTime date) {
    _recent.insert(
      0,
      JourneySearchRecord(
        from: from,
        to: to,
        date: date,
        searchedAt: DateTime.now(),
      ),
    );
    unawaited(
      _store(
        'recent_journeys',
        _recent
            .take(30)
            .map(
              (j) => jsonEncode({
                'from': j.from,
                'to': j.to,
                'date': j.date.toIso8601String(),
                'searchedAt': j.searchedAt.toIso8601String(),
              }),
            )
            .toList(),
      ),
    );
  }

  List<JourneySearchRecord> get recent => List.unmodifiable(_recent);
  List<BusService> get savedBuses =>
      _knownBuses.values.where((b) => _saved.contains(b.id)).toList();
  bool isSaved(String id) => _saved.contains(id);
  void toggleSaved(String id) {
    _saved.contains(id) ? _saved.remove(id) : _saved.add(id);
    unawaited(_store('saved_bus_ids', _saved.toList()));
  }

  void addComplaint(PassengerComplaint item) {
    _complaints.insert(0, item);
    unawaited(
      _store(
        'demo_complaints',
        _complaints.map((c) => jsonEncode(c.toJson())).toList(),
      ),
    );
  }

  List<PassengerComplaint> get complaints => List.unmodifiable(_complaints);
}
