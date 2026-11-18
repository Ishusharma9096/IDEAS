import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/features/transit/data/transit_repository.dart';
import 'package:goabusconnect/theme/app_theme.dart';

class JourneySearch extends StatefulWidget {
  const JourneySearch({super.key});
  @override
  State<JourneySearch> createState() => _JourneySearchState();
}

class _JourneySearchState extends State<JourneySearch> {
  String? _from = 'Panaji';
  String? _to = 'Margao';
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  Future<void> _select(bool source) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final stop in TransitRepository.stops)
              ListTile(
                title: Text(stop.name),
                subtitle: Text(stop.area),
                onTap: () =>
                    Navigator.pop(context, stop.name.replaceAll(' KTC', '')),
              ),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => source ? _from = choice : _to = choice);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _date = date);
  }

  void _search() {
    final from = _from?.trim() ?? '', to = _to?.trim() ?? '';
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose both a starting point and destination.'),
        ),
      );
      return;
    }
    if (from.toLowerCase() == to.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting point and destination must differ.'),
        ),
      );
      return;
    }
    TransitRepository.instance.recordSearch(from, to, _date);
    context.push(
      Uri(
        path: '/results',
        queryParameters: {
          'from': from,
          'to': to,
          'date': _date.toIso8601String(),
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE8EFF1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLAN YOUR JOURNEY',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.radio_button_checked,
            color: AppTheme.primary,
          ),
          title: const Text('From'),
          subtitle: Text(_from ?? 'Select starting point'),
          onTap: () => _select(true),
        ),
        Row(
          children: [
            const Expanded(child: Divider(indent: 16)),
            IconButton(
              tooltip: 'Swap locations',
              onPressed: () => setState(() {
                final previous = _from;
                _from = _to;
                _to = previous;
              }),
              icon: const Icon(Icons.swap_vert, color: AppTheme.primary),
            ),
            const Expanded(child: Divider(endIndent: 16)),
          ],
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on, color: Color(0xFFE18A50)),
          title: const Text('To'),
          subtitle: Text(_to ?? 'Select destination'),
          onTap: () => _select(false),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Journey date'),
          subtitle: Text(
            MaterialLocalizations.of(context).formatMediumDate(_date),
          ),
          onTap: _pickDate,
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search),
            label: const Text('Find Buses'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Local demo records are unverified and for interface testing only.',
          style: TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
      ],
    ),
  );
}
