import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import 'activation_screen.dart';
import 'login_screen.dart';
import 'tourist_redeem_screen.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anmeldung')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Willkommen in der Gemeinde App',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bitte melde dich an oder aktiviere deinen Zugangscode.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                AppRouterScope.of(context).push(const TouristRedeemScreen());
              },
              child: const Text('Tourist-Zugang'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                AppRouterScope.of(context).push(const ActivationScreen());
              },
              child: const Text('Ich habe einen Aktivierungscode'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                AppRouterScope.of(context).push(const LoginScreen());
              },
              child: const Text('Ich habe bereits ein Konto'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
