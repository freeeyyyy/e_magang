import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/auth_provider.dart';
import 'package:emagang_app/presentation/providers/siswa_provider.dart';
import 'package:emagang_app/data/models/user_model.dart';
import 'package:emagang_app/data/models/absensi_model.dart';

class DashboardSiswaScreen extends StatefulWidget {
  const DashboardSiswaScreen({super.key});

  @override
  State<DashboardSiswaScreen> createState() => _DashboardSiswaScreenState();
}

class _DashboardSiswaScreenState extends State<DashboardSiswaScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SiswaProvider>(context, listen: false).fetchDashboardData();
    });
  }

  void _handleOpenChat() {
    context.push('/siswa/chat');
  }

  void _handleRequestSertifikat(SiswaProvider provider) async {
    final status = provider.statusSertifikat['status'];

    if (status == 'Tersedia') {
      // Sertifikat sudah siap → unduh
      final url = provider.statusSertifikat['download_url'] ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Membuka sertifikat: $url'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (status == 'Menunggu Review') {
      // Sudah diajukan, masih di-review
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan Anda sedang ditinjau oleh admin. Harap bersabar.'),
          backgroundColor: AppTheme.info,
        ),
      );
    } else if (status == 'Sedang Diproses') {
      // Admin sedang menyiapkan sertifikat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sertifikat Anda sedang disiapkan oleh admin.'),
          backgroundColor: AppTheme.warning,
        ),
      );
    } else {
      // Belum diajukan → ajukan sekarang
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Color(0xFF6A1B9A)),
              SizedBox(width: 8),
              Text('Ajukan Sertifikat', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: const Text(
            'Pastikan seluruh kegiatan magang sudah terdokumentasi dengan baik.\n\n'
            'Setelah diajukan, admin akan memverifikasi dan menerbitkan sertifikat Anda. '
            'Proses ini membutuhkan waktu beberapa hari kerja.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ajukan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await provider.ajukanSertifikat();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Pengajuan sertifikat berhasil dikirim! Admin akan segera meninjau.'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final siswa = Provider.of<SiswaProvider>(context);
    final user = auth.user;

    // Calculate present count
    final hadirCount = siswa.riwayatAbsensi.where((e) => e.statusMasuk == 'Hadir' || e.statusMasuk == 'Terlambat').length;
    final progress = siswa.statusSertifikat['progres'] ?? 0.0;
    final int progressPercent = (progress * 100).toInt();

    // Check today's attendance status
    final today = DateTime.now();
    AbsensiModel? todayAbsen;
    try {
      todayAbsen = siswa.riwayatAbsensi.firstWhere(
        (e) => e.tanggal.day == today.day && e.tanggal.month == today.month && e.tanggal.year == today.year,
      );
    } catch (_) {
      todayAbsen = null;
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Dashboard Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: _handleOpenChat,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => siswa.fetchDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile card header
              _buildProfileHeader(user),
              const SizedBox(height: 16),

              // 2. Daily Report Reminder banner
              if (siswa.riwayatLaporan.isEmpty || 
                  (siswa.riwayatLaporan.isNotEmpty && 
                   siswa.riwayatLaporan.first.tanggal.day != DateTime.now().day))
                _buildReminderBanner(),

              const SizedBox(height: 16),

              // 3. Stats Grid
              _buildStatsGrid(hadirCount, siswa.riwayatLaporan.where((e) => e.status == 'Pending').length, progressPercent),
              const SizedBox(height: 20),

              // 4. Quick Actions
              const Text(
                'Menu Utama',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              _buildQuickActionsGrid(context, siswa),
              const SizedBox(height: 20),

              // 5. Today's Attendance Card
              const Text(
                'Kehadiran Hari Ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              _buildTodayAttendanceCard(todayAbsen),
              const SizedBox(height: 20),

              // 6. Recent Daily Report Log
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Laporan Harian Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => context.push('/siswa/laporan'),
                    child: const Text('Lihat Semua'),
                  )
                ],
              ),
              _buildRecentReportsList(siswa),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              user?.nama.substring(0, 1).toUpperCase() ?? 'S',
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.nama ?? 'Siswa Magang',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'NIS: ${user?.nis ?? "-"}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        user?.tempatMagang ?? 'Tempat Magang',
                         style: const TextStyle(fontSize: 12, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildReminderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: AppTheme.warning, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengingat Laporan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                ),
                Text(
                  'Jangan lupa kirim laporan harian kegiatan magang Anda hari ini!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF92400E)),
            onPressed: () => context.push('/siswa/laporan'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int hadir, int pendingLaporan, int progresPercent) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Kehadiran', '$hadir Hari', Icons.calendar_today, AppTheme.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Lap. Pending', '$pendingLaporan Berkas', Icons.article_outlined, AppTheme.info),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Progres Magang', '$progresPercent%', Icons.trending_up_rounded, AppTheme.accentColor),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, SiswaProvider provider) {
    final certStatus = provider.statusSertifikat['status'] ?? 'Belum Diajukan';
    Color certColor = AppTheme.textSecondary;
    IconData certIcon = Icons.workspace_premium_rounded;
    String certLabel = 'Sertifikat';

    if (certStatus == 'Tersedia') {
      certColor = AppTheme.success;
      certIcon = Icons.download_rounded;
      certLabel = 'Unduh Sertifikat';
    } else if (certStatus == 'Menunggu Review') {
      certColor = AppTheme.warning;
      certIcon = Icons.hourglass_empty_rounded;
      certLabel = 'Menunggu Review';
    } else if (certStatus == 'Sedang Diproses') {
      certColor = AppTheme.info;
      certIcon = Icons.settings_rounded;
      certLabel = 'Diproses Admin';
    } else {
      certLabel = 'Ajukan Sertifikat';
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: [
        _buildActionItem('Scan QR', Icons.qr_code_scanner_rounded, AppTheme.primaryColor, () => context.push('/siswa/scan-qr')),
        _buildActionItem('Isi Laporan', Icons.note_add_rounded, AppTheme.accentColor, () => context.push('/siswa/laporan')),
        _buildActionItem('Ajukan Izin', Icons.medical_services_rounded, AppTheme.danger, () => context.push('/siswa/izin')),
        _buildActionItem(certLabel, certIcon, certColor, () => _handleRequestSertifikat(provider)),
        _buildActionItem('Chat Admin', Icons.chat_rounded, const Color(0xFF0277BD), _handleOpenChat),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceCard(AbsensiModel? todayAbsen) {
    String formatTime(DateTime? t) => t == null ? '--:--' : DateFormat('HH:mm').format(t);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              if (todayAbsen != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Aktif',
                    style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.login, color: AppTheme.success),
                    const SizedBox(height: 4),
                    const Text('Masuk', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      formatTime(todayAbsen?.waktuMasuk),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    if (todayAbsen?.statusMasuk != null)
                      Text(
                        todayAbsen!.statusMasuk,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: todayAbsen.statusMasuk == 'Terlambat' ? AppTheme.warning : AppTheme.success,
                        ),
                      ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: AppTheme.borderSoft),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.logout, color: AppTheme.danger),
                    const SizedBox(height: 4),
                    const Text('Pulang', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      formatTime(todayAbsen?.waktuKeluar),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    if (todayAbsen?.statusKeluar != null)
                      Text(
                        todayAbsen!.statusKeluar!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsList(SiswaProvider provider) {
    if (provider.loadingLaporan) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (provider.riwayatLaporan.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text('Belum ada laporan dikirim minggu ini.', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    final displayList = provider.riwayatLaporan.take(3).toList();

    return Column(
      children: displayList.map((laporan) {
        Color statusColor = AppTheme.warning;
        if (laporan.status == 'Disetujui') statusColor = AppTheme.success;
        if (laporan.status == 'Ditolak') statusColor = AppTheme.danger;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMM yyyy', 'id_ID').format(laporan.tanggal),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        laporan.status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  laporan.kegiatan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                if (laporan.catatanPembimbing != null && laporan.catatanPembimbing!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Catatan: ${laporan.catatanPembimbing}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
