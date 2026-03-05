import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../layout/admin_layout.dart';
import '../theme/admin_theme.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AdminTheme.theme(context), child: const _AdminGate());
  }
}

class _AdminGate extends StatelessWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;

    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: supabase
          .from('users')
          .select('role')
          .eq('auth_id', authUser.id)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!['role'] != 'admin') {
          return const Scaffold(body: Center(child: Text('Unauthorized')));
        }

        return const AdminLayout();
      },
    );
  }
}
