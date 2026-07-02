import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/auth_provider.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => admin.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(auth.user?.nama ?? 'Admin', today),
                    const SizedBox(height: 20),

                    // Statistik Cards
                    const Text(
                      'Ringkasan Hari Ini',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid(admin),
                    const SizedBox(height: 24),

                    // Menu Admin
                    const Text(
                      'Menu Pengelolaan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuGrid(context, admin),
                    const SizedBox(height: 24),

                    // Laporan Pending terbaru
                    _buildPendingSection(admin),
                    const SizedBox(height: 24),

                    // Izin Pending terbaru
                    _buildIzinPendingSection(admin),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String nama, DateTime today) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang,',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  nama,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(today),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminProvider admin) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildStatCard('Siswa Aktif', '${admin.totalSiswaAktif}',
            'Total peserta magang', Icons.school_rounded, const Color(0xFF1A237E)),
        _buildStatCard('Hadir Hari Ini', '${admin.absensiHariIni}',
            'Dari ${admin.totalSiswaAktif} siswa', Icons.how_to_reg_rounded, AppTheme.success),
        _buildStatCard('Laporan Pending', '${admin.totalLaporanPending}',
            'Butuh verifikasi', Icons.article_outlined, AppTheme.warning),
        _buildStatCard('Izin Pending', '${admin.totalIzinPending}',
            'Butuh persetujuan', Icons.medical_services_outlined, AppTheme.danger),
        _buildStatCard('Sertifikat', '${admin.totalSertifikatPending}',
            'Menunggu diproses', Icons.workspace_premium_rounded, const Color(0xFF6A1B9A)),
        _buildStatCard('Pesan Baru', '${admin.totalUnreadChat}',
            'Dari siswa', Icons.chat_bubble_rounded, const Color(0xFF0277BD)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, AdminProvider admin) {
    final menus = [
      {
        'label': 'Daftar Siswa',
        'icon': Icons.people_rounded,
        'color': const Color(0xFF1A237E),
        'route': '/admin/siswa',
        'badge': null,
      },
      {
        'label': 'Rekap Absensi',
        'icon': Icons.calendar_month_rounded,
        'color': AppTheme.success,
        'route': '/admin/absensi',
        'badge': null,
      },
      {
        'label': 'Verifikasi Laporan',
        'icon': Icons.fact_check_rounded,
        'color': AppTheme.warning,
        'route': '/admin/laporan',
        'badge': admin.totalLaporanPending > 0 ? '${admin.totalLaporanPending}' : null,
      },
      {
        'label': 'Verifikasi Izin',
        'icon': Icons.medical_information_rounded,
        'color': AppTheme.danger,
        'route': '/admin/izin',
        'badge': admin.totalIzinPending > 0 ? '${admin.totalIzinPending}' : null,
      },
      {
        'label': 'Sertifikat',
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xFF6A1B9A),
        'route': '/admin/sertifikat',
        'badge': admin.totalSertifikatPending > 0 ? '${admin.totalSertifikatPending}' : null,
      },
      {
        'label': 'Pesan Siswa',
        'icon': Icons.chat_rounded,
        'color': const Color(0xFF0277BD),
        'route': '/admin/chat',
        'badge': admin.totalUnreadChat > 0 ? '${admin.totalUnreadChat}' : null,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: menus.map((m) {
        return _buildMenuCard(
          context,
          label: m['label'] as String,
          icon: m['icon'] as IconData,
          color: m['color'] as Color,
          route: m['route'] as String,
          badge: m['badge'] as String?,
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required String route,
    String? badge,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection(AdminProvider admin) {
    final pendingLaporan = admin.semuaLaporan
        .where((m) => (m['laporan'] as dynamic).status == 'Pending')
        .take(3)
        .toList();

    if (pendingLaporan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Laporan Perlu Diverifikasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () => context.push('/admin/laporan'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...pendingLaporan.map((m) {
          final siswa = m['siswa'] as dynamic;
          final laporan = m['laporan'] as dynamic;
          return _buildPendingCard(
            siswa.nama as String,
            DateFormat('d MMM yyyy', 'id_ID').format(laporan.tanggal as DateTime),
            laporan.kegiatan as String,
            Icons.article_outlined,
            AppTheme.warning,
          );
        }),
      ],
    );
  }

  Widget _buildIzinPendingSection(AdminProvider admin) {
    final pendingIzin = admin.semuaIzin
        .where((m) => (m['izin'] as dynamic).status == 'Pending')
        .take(3)
        .toList();

    if (pendingIzin.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Izin Perlu Disetujui',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () => context.push('/admin/izin'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...pendingIzin.map((m) {
          final siswa = m['siswa'] as dynamic;
          final izin = m['izin'] as dynamic;
          return _buildPendingCard(
            siswa.nama as String,
            '${izin.tipe} - ${DateFormat('d MMM', 'id_ID').format(izin.tanggalMulai as DateTime)}',
            izin.keterangan as String,
            Icons.medical_services_outlined,
            AppTheme.danger,
          );
        }),
      ],
    );
  }

  Widget _buildPendingCard(String name, String meta, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                Text(meta, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
