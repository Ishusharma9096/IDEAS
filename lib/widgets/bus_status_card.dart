import 'package:flutter/material.dart';
import 'package:goabusconnect/theme/app_theme.dart';

enum BusStatusType { live, reported, scheduled }

class BusStatusCard extends StatelessWidget {
  final BusStatusType status;

  const BusStatusCard({super.key, required this.status});

  String get title {
    switch (status) {
      case BusStatusType.live:
        return 'LIVE';
      case BusStatusType.reported:
        return 'REPORTED';
      case BusStatusType.scheduled:
        return 'SCHEDULED';
    }
  }

  String get description {
    switch (status) {
      case BusStatusType.live:
        return 'Requires a connected GPS feed and a visible update time';
      case BusStatusType.reported:
        return 'Passenger or operator updates show their source and review state';
      case BusStatusType.scheduled:
        return 'Published timetable information; this is not live tracking';
    }
  }

  Color get statusColor {
    switch (status) {
      case BusStatusType.live:
        return const Color(0xFF168A62);
      case BusStatusType.reported:
        return const Color(0xFFD18A27);
      case BusStatusType.scheduled:
        return const Color(0xFF477DAA);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case BusStatusType.live:
        return Icons.gps_fixed_rounded;
      case BusStatusType.reported:
        return Icons.verified_rounded;
      case BusStatusType.scheduled:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EFF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 23),
          ),
          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
              ],
            ),
          ),

          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
