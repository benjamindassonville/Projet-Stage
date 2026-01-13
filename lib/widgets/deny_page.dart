import 'package:flutter/material.dart';

class DenyPage extends StatelessWidget {
  final String message;
  const DenyPage({super.key, this.message = "Accès refusé."});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accès refusé")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
