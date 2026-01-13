import 'package:flutter/material.dart';
import 'deny_page.dart';

class PermissionRoute extends StatelessWidget {
  final Set<String> permissions;
  final String requiredPermission;
  final Widget page;
  final String? denyMessage;

  const PermissionRoute({
    super.key,
    required this.permissions,
    required this.requiredPermission,
    required this.page,
    this.denyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final allowed = permissions.contains(requiredPermission);
    if (allowed) return page;

    return DenyPage(message: denyMessage ?? "Vous n'avez pas les droits nécessaires.");
  }
}
