import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../providers/expense_providers.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.chart_pie_fill, size: 80, color: Color(0xFF5E5CE6)),
            const SizedBox(height: 24),
            const Text('Expense Tracker', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 48),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              borderRadius: BorderRadius.circular(16),
              child: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                try {
                  if (Firebase.apps.isNotEmpty) {
                    final auth = ref.read(authServiceProvider);
                    await auth.signInWithGoogle();
                    return;
                  }
                } catch (e) {
                  print('Firebase Login Bypass: $e');
                }
                
                // Fallback to Local Mock Mode if Firebase isn't configured
                ref.read(isMockLoggedInProvider.notifier).login();
              },
            )
          ],
        ),
      ),
    );
  }
}
