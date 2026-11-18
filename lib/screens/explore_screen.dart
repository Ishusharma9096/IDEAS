import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/theme/app_theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Goa',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discover your next journey',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Find routes, stops and bus services in one place.',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),

            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search bus routes or stops',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Explore by category',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _ExploreCategory(
                    icon: Icons.route_rounded,
                    title: 'Bus Routes',
                    subtitle: 'Discover routes',
                    onTap: () => context.push('/routes'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _ExploreCategory(
                    icon: Icons.location_on_rounded,
                    title: 'Bus Stops',
                    subtitle: 'Find nearby stops',
                    onTap: () => context.push('/stops'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Popular destinations',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 14),

            const _DestinationCard(
              name: 'Panaji',
              description: 'Capital city of Goa',
              icon: Icons.location_city_rounded,
            ),
            const _DestinationCard(
              name: 'Margao',
              description: 'Explore South Goa',
              icon: Icons.place_rounded,
            ),
            const _DestinationCard(
              name: 'Mapusa',
              description: 'Explore North Goa',
              icon: Icons.explore_rounded,
            ),
            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: () => context.push('/tracking'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open map and tracking availability'),
            ),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4F5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Route and destination information will be '
                      'connected to verified transport data.',
                      style: TextStyle(
                        color: AppTheme.darkTeal,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExploreCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE8EFF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primary, size: 27),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;

  const _DestinationCard({
    required this.name,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EFF1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.10),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: AppTheme.muted,
          ),
        ],
      ),
    );
  }
}
