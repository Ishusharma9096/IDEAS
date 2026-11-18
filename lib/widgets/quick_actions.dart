import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.directions_bus_rounded,
        title: 'Find Buses',
        subtitle: 'Explore routes',
        color: const Color(0xFF087E8B),
      ),
      _ActionItem(
        icon: Icons.near_me_rounded,
        title: 'Nearby Stops',
        subtitle: 'Stops around you',
        color: const Color(0xFF3985B8),
      ),
      _ActionItem(
        icon: Icons.route_rounded,
        title: 'Plan Journey',
        subtitle: 'Compare routes',
        color: const Color(0xFF168A72),
      ),
      _ActionItem(
        icon: Icons.local_offer_rounded,
        title: 'Offers',
        subtitle: 'Save more',
        color: const Color(0xFFE69B38),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 105,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => context.push(switch (action.title) {
              'Nearby Stops' => '/stops',
              'Offers' => '/offers',
              _ => '/routes',
            }),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFE8EFF1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(action.icon, color: action.color, size: 23),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          action.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
