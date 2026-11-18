import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goabusconnect/app/app.dart';
import 'package:goabusconnect/features/transit/data/transit_repository.dart';
import 'package:goabusconnect/core/services/supabase_service.dart';

export 'app/app.dart' show GoaBusConnectApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await TransitRepository.instance.initialize();
  } catch (_) {
    // Demo mode remains available if local storage cannot be opened.
  }
  try {
    await SupabaseService.initializeIfConfigured();
  } catch (_) {
    // An unreachable backend should not block local demo mode.
  }
  runApp(const ProviderScope(child: GoaBusConnectApp()));
}
