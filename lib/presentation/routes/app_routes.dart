import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/ortu/dashboard_ortu_screen.dart';
import '../screens/siswa/dashboard_siswa_screen.dart';
import '../screens/siswa/laporan_harian_screen.dart';
import '../screens/siswa/pengajuan_izin_screen.dart';
import '../screens/siswa/scan_qr_screen.dart';
import '../screens/siswa/chat_screen.dart';
import '../screens/admin/dashboard_admin_screen.dart';
import '../screens/admin/daftar_siswa_screen.dart';
import '../screens/admin/rekap_absensi_screen.dart';
import '../screens/admin/verifikasi_laporan_screen.dart';
import '../screens/admin/verifikasi_izin_screen.dart';
import '../screens/admin/detail_siswa_screen.dart';
import '../screens/admin/chat_admin_screen.dart';
import '../screens/admin/manajemen_sertifikat_screen.dart';
import '../../data/models/user_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  // Siswa
  static const String siswaDashboard = '/siswa/dashboard';
  static const String siswaScanQr    = '/siswa/scan-qr';
  static const String siswaLaporan   = '/siswa/laporan';
  static const String siswaIzin      = '/siswa/izin';
  static const String siswaChat      = '/siswa/chat';

  // Ortu
  static const String ortuDashboard = '/ortu/dashboard';

  // Admin
  static const String adminDashboard   = '/admin/dashboard';
  static const String adminSiswa       = '/admin/siswa';
  static const String adminAbsensi     = '/admin/absensi';
  static const String adminLaporan     = '/admin/laporan';
  static const String adminIzin        = '/admin/izin';
  static const String adminSertifikat  = '/admin/sertifikat';
  static const String adminChat        = '/admin/chat';
  static const String adminDetailSiswa = '/admin/siswa/:id';

  static GoRouter getRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        if (!authProvider.initialized) return splash;

        final bool loggedIn  = authProvider.isAuthenticated;
        final bool loggingIn = state.matchedLocation == login;
        final userRole = authProvider.user?.role;

        // 1. Belum login → paksa ke login
        if (!loggedIn) {
          return loggingIn ? null : login;
        }

        // 2. Sudah login, ada di splash/login → arahkan ke dashboard role-nya
        if (loggingIn || state.matchedLocation == splash) {
          if (userRole == UserRole.siswa)  return siswaDashboard;
          if (userRole == UserRole.ortu)   return ortuDashboard;
          if (userRole == UserRole.admin)  return adminDashboard;
        }

        // 3. Cegah akses lintas role
        final loc = state.matchedLocation;
        if (loc.startsWith('/siswa') && userRole != UserRole.siswa) {
          return userRole == UserRole.admin ? adminDashboard : ortuDashboard;
        }
        if (loc.startsWith('/ortu') && userRole != UserRole.ortu) {
          return userRole == UserRole.admin ? adminDashboard : siswaDashboard;
        }
        if (loc.startsWith('/admin') && userRole != UserRole.admin) {
          return userRole == UserRole.siswa ? siswaDashboard : ortuDashboard;
        }

        return null;
      },
      routes: [
        // ── Splash ───────────────────────────────────────────────────────
        GoRoute(
          path: splash,
          builder: (context, state) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),

        // ── Auth ─────────────────────────────────────────────────────────
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),

        // ── Siswa Routes ─────────────────────────────────────────────────
        GoRoute(
          path: siswaDashboard,
          builder: (context, state) => const DashboardSiswaScreen(),
        ),
        GoRoute(
          path: siswaScanQr,
          builder: (context, state) => const ScanQrScreen(),
        ),
        GoRoute(
          path: siswaLaporan,
          builder: (context, state) => const LaporanHarianScreen(),
        ),
        GoRoute(
          path: siswaIzin,
          builder: (context, state) => const PengajuanIzinScreen(),
        ),
        GoRoute(
          path: siswaChat,
          builder: (context, state) => const ChatSiswaScreen(),
        ),

        // ── Ortu Routes ──────────────────────────────────────────────────
        GoRoute(
          path: ortuDashboard,
          builder: (context, state) => const DashboardOrtuScreen(),
        ),

        // ── Admin Routes ─────────────────────────────────────────────────
        GoRoute(
          path: adminDashboard,
          builder: (context, state) => const DashboardAdminScreen(),
        ),
        GoRoute(
          path: adminSiswa,
          builder: (context, state) => const DaftarSiswaScreen(),
        ),
        GoRoute(
          path: adminAbsensi,
          builder: (context, state) => const RekapAbsensiScreen(),
        ),
        GoRoute(
          path: adminLaporan,
          builder: (context, state) => const VerifikasiLaporanScreen(),
        ),
        GoRoute(
          path: adminIzin,
          builder: (context, state) => const VerifikasiIzinScreen(),
        ),
        GoRoute(
          path: adminSertifikat,
          builder: (context, state) => const ManajemenSertifikatScreen(),
        ),
        GoRoute(
          path: adminChat,
          builder: (context, state) => const ChatAdminScreen(),
        ),
        GoRoute(
          path: adminDetailSiswa,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return DetailSiswaScreen(siswaId: id);
          },
        ),
      ],
    );
  }
}
