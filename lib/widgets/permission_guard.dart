import 'package:flutter/material.dart';

class PermissionGuard extends StatelessWidget {
  final Set<String> permissions;
  final String requiredPermission;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.permissions,
    required this.requiredPermission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final allowed = permissions.contains(requiredPermission);
    if (allowed) return child;

    return fallback ??
        const SizedBox.shrink(); // Par défaut: invisible (propre en UI)
  }
}
