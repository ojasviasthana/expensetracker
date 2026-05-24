import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home/home_page.dart';
import 'analytics/analytics_page.dart';
import 'settings/settings_page.dart';
import 'login/login_page.dart';
import 'providers/expense_providers.dart';

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginPage();
        
        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar_fill), label: 'Analytics'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Settings'),
            ],
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              builder: (context) {
                switch (index) {
                  case 0: return const HomePage();
                  case 1: return const AnalyticsPage();
                  case 2: return const SettingsPage();
                  default: return const HomePage();
                }
              },
            );
          },
        );
      },
      loading: () => const CupertinoPageScaffold(child: Center(child: CupertinoActivityIndicator())),
      error: (e, st) => CupertinoPageScaffold(child: Center(child: Text('Auth Error: $e'))),
    );
  }
}
