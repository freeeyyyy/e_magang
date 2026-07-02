import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/auth_provider.dart';
import 'package:emagang_app/presentation/providers/ortu_provider.dart';
import 'package:emagang_app/data/models/user_model.dart';

class DashboardOrtuScreen extends StatefulWidget {
  const DashboardOrtuScreen({super.key});

  @override
  State<DashboardOrtuScreen> createState() => _DashboardOrtuScreenState();
}

class _DashboardOrtuScreenState extends State<DashboardOrtuScreen> {
  @override
  void initState() {
    super.initState();
    // Load monitoring data on opening dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user?.idAnak != null) {
        Provider.of<OrtuProvider>(context, listen: false)
            .loadMonitoringData(auth.user!.idAnak!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ortu = Provider.of<OrtuProvider>(context);
    final user = auth.user;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.lightBg,
        appBar: AppBar(
          title: const Text('Monitoring Orang Tua'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => auth.logout(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.how_to_reg_rounded), text: 'Presensi'),
              Tab(icon: Icon(Icons.menu_book_rounded), text: 'Laporan'),
              Tab(icon: Icon(Icons.sick_rounded), text: 'Izin/Sakit'),
            ],
          ),
        ),
        body: ortu.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  if (user?.idAnak != null) {
                    await ortu.loadMonitoringData(user!.idAnak!);
                  }
                },
                child: Column(
                  children: [
                    // Parent and child information banner
                    _buildMonitoringHeader(user),
                    
                    // Child progress overview
                    _buildProgressOverviewCard(ortu),

                    const SizedBox(height: 8),

                    // Tab View Contents (Read-only data lists)
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Attendance Logs
                          _buildPresensiList(ortu),

                          // Tab 2: Laporan Harian List
                          _buildLaporanList(ortu),

                          // Tab 3: Izin/Sakit List
                          _buildIzinList(ortu),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMonitoringHeader(UserModel? user) {
    return Container(
      width: double.infinity,
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        color: Colors.white.withOpacity(0.15),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wali: ${user?.nama ?? "-"}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Memantau Anak: ${user?.namaAnak ?? "-"} (NIS: ${user?.nisAnak ?? "-"})',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverviewCard(OrtuProvider provider) {
    final progress = provider.anakProgres['progres'] ?? 0.0;
    final int progressPercent = (progress * 100).toInt();
    final statusMagang = provider.anakProgres['status_magang'] ?? 'Aktif';
    final certStatus = provider.anakProgres['sertifikat_status'] ?? 'Belum Diajukan';
    final certUrl = provider.anakProgres['sertifikat_url'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Progres Magang Anak',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusMagang,
                  style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: AppTheme.borderSoft,
                      color: AppTheme.accentColor,
                    ),
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.accentColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telah menyelesaikan ${provider.anakProgres["hari_terisi"] ?? 0} dari ${provider.anakProgres["total_hari"] ?? 0} hari magang.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status Sertifikat: ${_labelSertifikat(certStatus)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (certStatus == 'Tersedia' && certUrl != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.cloud_download, size: 18),
                label: const Text('Unduh Sertifikat Magang Anak', style: TextStyle(fontSize: 13)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mengunduh berkas sertifikat dari: $certUrl')),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _labelSertifikat(String status) {
    switch (status) {
      case 'Tersedia':         return '✅ Telah Terbit (Bisa Diunduh)';
      case 'Menunggu Review':  return '🕐 Menunggu Ditinjau Admin';
      case 'Sedang Diproses':  return '⚙️ Sedang Disiapkan Admin';
      case 'Ditolak':          return '❌ Ditolak Admin';
      default:                 return '— Belum Diajukan';
    }
  }

  Widget _buildPresensiList(OrtuProvider provider) {
    if (provider.anakAbsensi.isEmpty) {
      return const Center(child: Text('Belum ada riwayat kehadiran anak.'));
    }

    String formatTime(DateTime? t) => t == null ? '--:--' : DateFormat('HH:mm').format(t);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.anakAbsensi.length,
      itemBuilder: (context, index) {
        final absen = provider.anakAbsensi[index];
        final bool terlambat = absen.statusMasuk == 'Terlambat';
        final bool alpa = absen.statusMasuk == 'Alpa';

        Color statusColor = AppTheme.success;
        if (terlambat) statusColor = AppTheme.warning;
        if (alpa) statusColor = AppTheme.danger;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alpa ? Icons.close_rounded : Icons.check_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMM yyyy', 'id_ID').format(absen.tanggal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Masuk: ${formatTime(absen.waktuMasuk)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(width: 12),
                          Text('Pulang: ${formatTime(absen.waktuKeluar)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    absen.statusMasuk,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLaporanList(OrtuProvider provider) {
    if (provider.anakLaporan.isEmpty) {
      return const Center(child: Text('Belum ada laporan harian magang.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.anakLaporan.length,
      itemBuilder: (context, index) {
        final laporan = provider.anakLaporan[index];
        Color statusColor = AppTheme.warning;
        if (laporan.status == 'Disetujui') statusColor = AppTheme.success;
        if (laporan.status == 'Ditolak') statusColor = AppTheme.danger;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(laporan.tanggal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
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
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
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
                      'Tanggapan Pembimbing: ${laporan.catatanPembimbing}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIzinList(OrtuProvider provider) {
    if (provider.anakIzin.isEmpty) {
      return const Center(child: Text('Belum ada riwayat izin/sakit anak.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.anakIzin.length,
      itemBuilder: (context, index) {
        final izin = provider.anakIzin[index];
        Color statusColor = AppTheme.warning;
        if (izin.status == 'Disetujui') statusColor = AppTheme.success;
        if (izin.status == 'Ditolak') statusColor = AppTheme.danger;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          izin.tipe == 'Sakit' ? Icons.sick : Icons.assignment,
                          size: 18,
                          color: izin.tipe == 'Sakit' ? AppTheme.danger : AppTheme.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          izin.tipe,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        izin.status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Rentang: ${DateFormat("dd/MM/yyyy").format(izin.tanggalMulai)} s/d ${DateFormat("dd/MM/yyyy").format(izin.tanggalSelesai)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  izin.keterangan,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
