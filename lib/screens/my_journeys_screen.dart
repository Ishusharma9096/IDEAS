import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/features/transit/data/transit_repository.dart';
import 'package:goabusconnect/theme/app_theme.dart';

class MyJourneysScreen extends StatefulWidget {
  const MyJourneysScreen({super.key});
  @override
  State<MyJourneysScreen> createState() => _MyJourneysScreenState();
}

class _MyJourneysScreenState extends State<MyJourneysScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = TransitRepository.instance;
    final saved = repo.savedBuses;
    final recent = repo.recent;
    return Scaffold(
      appBar: AppBar(title: const Text('My Journeys')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Saved on this device. Cloud sync requires passenger sign-in.',
            style: TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Saved journeys',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (saved.isEmpty)
            const ListTile(title: Text('No saved journeys yet')),
          for (final bus in saved)
            ListTile(
              leading: const Icon(Icons.bookmark, color: AppTheme.primary),
              title: Text('${bus.from} → ${bus.to}'),
              subtitle: Text('${bus.identifier} · Unverified demo'),
              onTap: () => context.push('/bus-details?id=${bus.id}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => repo.toggleSaved(bus.id)),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Recent searches',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (recent.isEmpty)
            const ListTile(title: Text('No recent searches yet')),
          for (final item in recent)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('${item.from} → ${item.to}'),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatMediumDate(item.date)} · demo search',
              ),
              onTap: () => context.push(
                Uri(
                  path: '/results',
                  queryParameters: {'from': item.from, 'to': item.to},
                ).toString(),
              ),
            ),
        ],
      ),
    );
  }
}
