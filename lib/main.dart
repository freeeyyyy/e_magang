import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/services/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/siswa_repository_impl.dart';
import 'data/repositories/ortu_repository_impl.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/siswa_provider.dart';
import 'presentation/providers/ortu_provider.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian date formatting support
  await initializeDateFormatting('id_ID', null);

  // Initialize Core Services
  final secureStorage = SecureStorageService();
  final dioClient = DioClient(secureStorage);

  // Initialize Repositories (Interface implementations)
  final authRepository = AuthRepositoryImpl(dioClient, secureStorage);
  final siswaRepository = SiswaRepositoryImpl(dioClient);
  final ortuRepository = OrtuRepositoryImpl(dioClient);

  runApp(
    MultiProvider(
      providers: [
        // Register core service providers
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository, dioClient, secureStorage),
        ),
        
        // Register feature providers with repository injections
        ChangeNotifierProvider<SiswaProvider>(
          create: (_) => SiswaProvider(siswaRepository),
        ),
        ChangeNotifierProvider<OrtuProvider>(
          create: (_) => OrtuProvider(ortuRepository),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(dioClient),
        ),
      ],
      child: const EMagangApp(),
    ),
  );
}

class EMagangApp extends StatelessWidget {
  const EMagangApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get AuthProvider instance to configure reactive router
    final authProvider = Provider.of<AuthProvider>(context);
    final router = AppRoutes.getRouter(authProvider);

    return MaterialApp.router(
      title: 'E-Magang App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Aktifkan lokalisasi bahasa Indonesia untuk date picker, dll.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Bahasa Indonesia
        Locale('en', 'US'), // Fallback English
      ],
      locale: const Locale('id', 'ID'),
    );
  }
}
