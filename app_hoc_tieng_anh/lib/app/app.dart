import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class LingoUpApp extends StatelessWidget {
  const LingoUpApp({super.key});

  static final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: AppConfig.environment == 'development',
    );
  }
}

Widget buildApp() => const ProviderScope(child: LingoUpApp());
