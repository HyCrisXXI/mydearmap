// lib/core/widgets/auth_gate.dart
import 'package:mydearmap/core/widgets/app_shell.dart';
import 'package:mydearmap/features/auth/views/init_world_view.dart';
import 'package:mydearmap/features/auth/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  late final Stream<User?> _authStateChanges;
  bool _hasEnteredWorld = false;

  @override
  void initState() {
    super.initState();
    _authStateChanges = Supabase.instance.client.auth.onAuthStateChange.map(
      (event) => event.session?.user,
    );
  }

  void _resetWorld() {
    if (!_hasEnteredWorld) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _hasEnteredWorld = false);
    });
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

        if (snapshot.data == null) {
          _resetWorld();
          return const LoginView();
        }

        final supabaseUser = snapshot.data;
        final metadataName = supabaseUser?.userMetadata?['name'];
        final userName = metadataName is String && metadataName.isNotEmpty
            ? metadataName
            : supabaseUser?.email;
        if (!_hasEnteredWorld) {
          return InitWorldView(
            userName: userName,
            onEnterWorld: () {
              if (!mounted) return;
              setState(() => _hasEnteredWorld = true);
            },
          );
        }

        return const AppShell(initialIndex: 2);
      },
    );
  }
}
