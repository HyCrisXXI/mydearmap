// lib/core/widgets/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/features/map/views/map_view.dart';
import 'package:mydearmap/features/auth/views/login_view.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  late final Stream<User?> _authStateChanges;

  @override
  void initState() {
    super.initState();
    _authStateChanges = Supabase.instance.client.auth.onAuthStateChange.map(
      (event) => event.session?.user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MapView();
        }

        return const LoginView();
      },
    );
  }
}
