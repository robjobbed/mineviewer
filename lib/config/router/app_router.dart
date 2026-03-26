import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/miner_detail/miner_detail_screen.dart';
import '../../presentation/screens/add_miner/add_miner_screen.dart';
import '../../presentation/screens/discovery/discovery_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/alerts/alerts_screen.dart';
import '../../presentation/screens/alerts/alert_rules_screen.dart';
import '../../presentation/screens/pool_earnings/pool_earnings_screen.dart';
import '../../presentation/screens/profitability/profitability_screen.dart';
import '../../presentation/adaptive/adaptive_layout.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdaptiveScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/miner/:id',
            name: RouteNames.minerDetail,
            builder: (context, state) => MinerDetailScreen(
              minerId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/discovery',
            name: RouteNames.discovery,
            builder: (context, state) => const DiscoveryScreen(),
          ),
          GoRoute(
            path: '/add-miner',
            name: RouteNames.addMiner,
            builder: (context, state) => const AddMinerScreen(),
          ),
          GoRoute(
            path: '/alerts',
            name: RouteNames.alerts,
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/alerts/rules',
            name: RouteNames.alertRules,
            builder: (context, state) => const AlertRulesScreen(),
          ),
          GoRoute(
            path: '/earnings',
            name: RouteNames.poolEarnings,
            builder: (context, state) => const PoolEarningsScreen(),
          ),
          GoRoute(
            path: '/profitability',
            name: RouteNames.profitability,
            builder: (context, state) => const ProfitabilityScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
