import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/analytics_service.dart';
import 'core/api_client.dart';
import 'core/session_store.dart';
import 'core/theme.dart';
import 'screens/jobs_screen.dart';
import 'screens/login_screen.dart';
import 'state/auth_controller.dart';
import 'state/jobs_controller.dart';
import 'widgets/glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final analytics = AnalyticsService();
  await analytics.init();

  final sessionStore = SessionStore();
  final apiClient = ApiClient(baseUrl: await sessionStore.readBaseUrl());

  runApp(
    HelperPartnerApp(
      analytics: analytics,
      sessionStore: sessionStore,
      apiClient: apiClient,
    ),
  );
}

class HelperPartnerApp extends StatelessWidget {
  const HelperPartnerApp({
    super.key,
    required this.analytics,
    required this.sessionStore,
    required this.apiClient,
  });

  final AnalyticsService analytics;
  final SessionStore sessionStore;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(
            apiClient: apiClient,
            sessionStore: sessionStore,
            analytics: analytics,
          )..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => JobsController(apiClient: apiClient, analytics: analytics),
        ),
      ],
      child: MaterialApp(
        title: 'EzyHelpers Partner',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _RootView(),
      ),
    );
  }
}

/// Picks the first screen once the stored session has been checked.
class _RootView extends StatelessWidget {
  const _RootView();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;

    return switch (status) {
      AuthStatus.checking => const GlassScaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.signedOut => const LoginScreen(),
      AuthStatus.signedIn => const JobsScreen(),
    };
  }
}
