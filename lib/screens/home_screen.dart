import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/theme/app_theme.dart';
import 'package:goabusconnect/widgets/journey_search.dart';
import 'package:goabusconnect/widgets/quick_actions.dart';
import 'package:goabusconnect/widgets/bus_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppTheme.primary,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GoaBusConnect',
                            style: TextStyle(
                              color: AppTheme.navy,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'One Platform. All Buses. Better Journeys.',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppTheme.navy,
                        size: 27,
                      ),
                    ),
                    IconButton(
                      tooltip: 'My profile',
                      onPressed: () => context.push('/profile'),
                      icon: const CircleAvatar(
                        radius: 21,
                        backgroundColor: Color(0xFFE4F2F3),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Welcome section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, Traveller 👋',
                      style: TextStyle(
                        color: AppTheme.navy,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Where would you like to go today?',
                      style: TextStyle(color: AppTheme.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Journey search
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: JourneySearch(),
              ),

              const SizedBox(height: 28),

              // Quick actions
              _sectionHeading(context, 'Explore', 'See all'),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: QuickActions(),
              ),

              const SizedBox(height: 28),

              // Bus information
              _sectionHeading(context, 'Understand bus status', 'Know more'),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    BusStatusCard(status: BusStatusType.live),
                    BusStatusCard(status: BusStatusType.reported),
                    BusStatusCard(status: BusStatusType.scheduled),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_offer_outlined,
                      color: AppTheme.primary,
                    ),
                    title: const Text('Local offers'),
                    subtitle: const Text(
                      'No sponsored offers are connected yet.',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: () => context.push('/offers'),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Footer
              const Center(
                child: Text(
                  'MADE FOR BETTER JOURNEYS IN GOA',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(BuildContext context, String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.push(title == 'Explore' ? '/routes' : '/about-data'),
            child: Text(
              action,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
