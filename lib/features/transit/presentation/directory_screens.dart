import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/transit_repository.dart';

class RouteDirectoryScreen extends StatefulWidget {
  const RouteDirectoryScreen({super.key});
  @override
  State<RouteDirectoryScreen> createState() => _RouteDirectoryScreenState();
}

class _RouteDirectoryScreenState extends State<RouteDirectoryScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final routes = TransitRepository.instance.searchRoutes(q);
    return Scaffold(
      appBar: AppBar(title: const Text('Bus routes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search routes or stops',
            ),
            onChanged: (v) => setState(() => q = v),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('DEMO DATA · UNVERIFIED ROUTES'),
          ),
          if (routes.isEmpty) const Text('No matching demo route.'),
          for (final r in routes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.route),
                title: Text(r.name),
                subtitle: Text('${r.stops.length} stops · DEMO DATA'),
                onTap: () => context.push('/route-details?id=${r.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

class StopDirectoryScreen extends StatefulWidget {
  const StopDirectoryScreen({super.key});
  @override
  State<StopDirectoryScreen> createState() => _StopDirectoryScreenState();
}

class _StopDirectoryScreenState extends State<StopDirectoryScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final stops = TransitRepository.instance.searchStops(q);
    return Scaffold(
      appBar: AppBar(title: const Text('Bus stops')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search stops',
            ),
            onChanged: (v) => setState(() => q = v),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'DEMO DATA · Stop locations and arrivals are unverified',
            ),
          ),
          for (final s in stops)
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(s.name),
                subtitle: Text(s.area),
                onTap: () => context.push('/stop-details?id=${s.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final route = TransitRepository.instance.routeById(id);
    if (route == null) {
      return const Scaffold(body: Center(child: Text('Route not found')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(route.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Chip(label: Text('UNVERIFIED DEMO ROUTE')),
          Text('${route.from} → ${route.to}'),
          for (var i = 0; i < route.stops.length; i++)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(route.stops[i]),
              onTap: () => context.push(
                '/stop-details?id=${route.stops[i].toLowerCase().replaceAll(' ktc', '')}',
              ),
            ),
          FilledButton(
            onPressed: () => context.push(
              Uri(
                path: '/results',
                queryParameters: {'from': route.from, 'to': route.to},
              ).toString(),
            ),
            child: const Text('Search demo buses'),
          ),
        ],
      ),
    );
  }
}

class StopDetailScreen extends StatelessWidget {
  const StopDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final stop = TransitRepository.stops.where((s) => s.id == id).firstOrNull;
    if (stop == null) {
      return const Scaffold(body: Center(child: Text('Stop not found')));
    }
    final routes = TransitRepository.instance.routesForStop(stop.name);
    return Scaffold(
      appBar: AppBar(title: Text(stop.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Chip(label: Text('DEMO STOP · NO LIVE ARRIVALS')),
          Text(stop.area),
          const SizedBox(height: 18),
          const Text(
            'Routes serving this stop',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final r in routes)
            ListTile(
              leading: const Icon(Icons.route),
              title: Text(r.name),
              onTap: () => context.push('/route-details?id=${r.id}'),
            ),
          if (routes.isEmpty) const Text('No demo routes found.'),
        ],
      ),
    );
  }
}
