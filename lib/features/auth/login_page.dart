import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // temporaire pour test
            await Supabase.instance.client.auth.signInWithPassword(
              email: 'test@test.com',
              password: 'password',
            );
          },
          child: const Text('Se connecter (test)'),
        ),
      ),
    );
  }
}
