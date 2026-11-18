import 'package:flutter/material.dart';
import 'package:goabusconnect/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class InformationScreens {
  static Widget routes() => const _DirectoryScreen(
    title: 'Bus routes',
    icon: Icons.route_rounded,
    message: 'Verified route and operator information will appear here when a transport data source is connected.',
    action: 'View route details',
    actionPath: '/route-details',
  );

  static Widget stops() => const _DirectoryScreen(
    title: 'Bus stops',
    icon: Icons.location_on_rounded,
    message: 'Nearby stops and scheduled arrivals need location access and published stop data. No location has been estimated.',
    action: 'Browse routes',
    actionPath: '/routes',
  );

  static Widget tracking() => const _DirectoryScreen(
    title: 'Bus tracking',
    icon: Icons.gps_off_rounded,
    message: 'Live tracking is unavailable because no GPS feed is connected. This screen will only show a bus as LIVE when genuine GPS data is received.',
    action: 'See status guide',
    actionPath: '/about-data',
  );

  static Widget alerts() => const _DirectoryScreen(
    title: 'Travel alerts',
    icon: Icons.notifications_none_rounded,
    message: 'There are no connected transport alerts yet. Service notices will be shown here with their source and update time.',
    action: 'Report an issue',
    actionPath: '/reports',
  );

  static Widget offers() => const _DirectoryScreen(
    title: 'Local offers',
    icon: Icons.local_offer_outlined,
    message: 'No participating businesses or active offers are connected. Sample promotions are not presented as valid coupons.',
    action: 'About sponsored offers',
    actionPath: '/about-data',
  );

  static Widget report() => const _ReportScreen();

  static Widget results(String from, String to) =>
      _ResultsScreen(from: from, to: to);

  static Widget detail() => const _DirectoryScreen(
    title: 'Route details',
    icon: Icons.directions_bus_outlined,
    message: 'Select a route from verified transport data to see its stops and published timetable. No service details are available yet.',
    action: 'Browse routes',
  );

  static Widget aboutData() => const _DirectoryScreen(
    title: 'Information status',
    icon: Icons.verified_outlined,
    message: 'LIVE requires a current GPS feed. REPORTED updates show their submitter and verification state. SCHEDULED timings come from a published timetable and are not live ETAs.',
    action: 'Explore routes',
  );
}

class _DirectoryScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  final String action;
  final String actionPath;

  const _DirectoryScreen({
    required this.title,
    required this.icon,
    required this.message,
    required this.action,
    this.actionPath = '/about-data',
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EFF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppTheme.primary.withValues(alpha: .1),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: AppTheme.muted, height: 1.55),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => context.push(actionPath),
                icon: const Icon(Icons.info_outline),
                label: Text(action),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _StatusLegend(),
      ],
    ),
  );
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to read bus information',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy),
          ),
          SizedBox(height: 12),
          _LegendRow(
            label: 'LIVE',
            color: Color(0xFF168A62),
            text: 'GPS position with last update time',
          ),
          _LegendRow(
            label: 'REPORTED',
            color: Color(0xFFD18A27),
            text: 'Submitted update with source and verification state',
          ),
          _LegendRow(
            label: 'SCHEDULED',
            color: Color(0xFF477DAA),
            text: 'Published timetable, not live tracking',
          ),
        ],
      ),
    ),
  );
}

class _LegendRow extends StatelessWidget {
  final String label, text;
  final Color color;
  const _LegendRow({
    required this.label,
    required this.color,
    required this.text,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _ResultsScreen extends StatelessWidget {
  final String from, to;
  const _ResultsScreen({required this.from, required this.to});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Journey options')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    from,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppTheme.primary),
                Expanded(
                  child: Text(
                    to,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _StatusLegend(),
        const SizedBox(height: 18),
        const _EmptyNotice(
          icon: Icons.search_off_rounded,
          title: 'No verified journey options yet',
          message: 'We do not have a connected route or timetable source to match this journey. No bus services or arrival times have been invented.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/routes'),
          icon: const Icon(Icons.route),
          label: const Text('Browse available route data'),
        ),
      ],
    ),
  );
}

class _ReportScreen extends StatefulWidget {
  const _ReportScreen();
  @override
  State<_ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<_ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _route = TextEditingController();
  final _details = TextEditingController();
  String _issue = 'Bus delayed';
  bool _submitted = false;
  @override
  void dispose() {
    _route.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report a transport issue')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_submitted)
          const _EmptyNotice(
            icon: Icons.hourglass_top_rounded,
            title: 'Report preview',
            message: 'This report is available only in this session. It was not sent to moderation and is not shown as verified.',
          ),
        if (!_submitted)
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Help other passengers make informed decisions.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _issue,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                  ),
                  items:
                      const [
                            'Bus delayed',
                            'Bus not operating',
                            'Bus cancelled',
                            'Bus crowded',
                            'Stop-related issue',
                            'Other',
                          ]
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _issue = v ?? _issue),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _route,
                  decoration: const InputDecoration(
                    labelText: 'Route or stop (optional)',
                  ),
                  maxLength: 80,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _details,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 300,
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Add at least 5 characters.'
                      : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Reports are unverified until reviewed. Avoid sharing personal or sensitive information.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _submitted = true);
                    }
                  },
                  child: const Text('Preview report'),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _EmptyNotice extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const _EmptyNotice({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppTheme.primary),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
