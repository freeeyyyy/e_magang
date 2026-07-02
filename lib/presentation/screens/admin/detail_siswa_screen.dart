import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';
import 'package:emagang_app/data/models/absensi_model.dart';
import 'package:emagang_app/data/models/laporan_model.dart';
import 'package:emagang_app/data/models/izin_model.dart';

class DetailSiswaScreen extends StatefulWidget {
  final String siswaId;
  const DetailSiswaScreen({super.key, required this.siswaId});

  @override
  State<DetailSiswaScreen> createState() => _DetailSiswaScreenState();
}

class _DetailSiswaScreenState extends State<DetailSiswaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final siswa = admin.daftarSiswa.where((s) => s.id == widget.siswaId).firstOrNull;

    if (siswa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Siswa')),
        body: const Center(child: Text('Data siswa tidak ditemukan.')),
      );
    }

    final isAktif = siswa.status == 'Aktif';
    final progress = siswa.progressMagang;

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white24,
                              child: Text(
                                siswa.nama[0].toUpperCase(),
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(siswa.nama, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('NIS: ${siswa.nis}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text(siswa.sekolah, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isAktif ? AppTheme.success.withOpacity(0.25) : Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Text(
                                siswa.status,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progress Magang', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('d MMM yyyy', 'id_ID').format(siswa.tanggalMulai)} – ${DateFormat('d MMM yyyy', 'id_ID').format(siswa.tanggalSelesai)}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _buildStatItem('${siswa.totalHadir}', 'Hadir', AppTheme.success),
                  _buildStatDivider(),
                  _buildStatItem('${siswa.totalAlpa}', 'Alpa', AppTheme.danger),
                  _buildStatDivider(),
                  _buildStatItem('${siswa.totalIzin}', 'Izin', AppTheme.warning),
                  _buildStatDivider(),
                  _buildStatItem('${siswa.laporan.where((l) => l.status == "Disetujui").length}', 'Laporan ✓', AppTheme.info),
                ],
              ),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Absensi'),
                  Tab(text: 'Laporan'),
                  Tab(text: 'Izin'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAbsensiTab(siswa.absensi),
            _buildLaporanTab(siswa.laporan),
            _buildIzinTab(siswa.izin),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 32, color: AppTheme.borderSoft);
  }

  Widget _buildAbsensiTab(List<AbsensiModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Belum ada data absensi.', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final a = list[i];
        Color color = AppTheme.success;
        if (a.statusMasuk == 'Terlambat') color = AppTheme.warning;
        if (a.statusMasuk == 'Alpa')      color = AppTheme.danger;
        if (a.statusMasuk == 'Izin')      color = AppTheme.info;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(a.tanggal),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
                    ),
                    if (a.waktuMasuk != null)
                      Text(
                        'Masuk: ${DateFormat('HH:mm').format(a.waktuMasuk!)}  •  Pulang: ${a.waktuKeluar != null ? DateFormat('HH:mm').format(a.waktuKeluar!) : '--:--'}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(a.statusMasuk, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLaporanTab(List<LaporanModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Belum ada laporan.', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final l = list[i];
        Color color = AppTheme.warning;
        if (l.status == 'Disetujui') color = AppTheme.success;
        if (l.status == 'Ditolak')   color = AppTheme.danger;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('d MMM yyyy', 'id_ID').format(l.tanggal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(l.status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(l.kegiatan, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (l.catatanPembimbing != null) ...[
                  const SizedBox(height: 6),
                  Text('📝 ${l.catatanPembimbing}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIzinTab(List<IzinModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Tidak ada pengajuan izin/sakit.', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final iz = list[i];
        Color color = AppTheme.warning;
        if (iz.status == 'Disetujui') color = AppTheme.success;
        if (iz.status == 'Ditolak')   color = AppTheme.danger;
        final tipeColor = iz.tipe == 'Sakit' ? AppTheme.danger : AppTheme.warning;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: tipeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(iz.tipe, style: TextStyle(color: tipeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(iz.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('d MMM yyyy', 'id_ID').format(iz.tanggalMulai)} – ${DateFormat('d MMM yyyy', 'id_ID').format(iz.tanggalSelesai)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(iz.keterangan, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (iz.lampiranUrl != null) ...[
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.attach_file_rounded, size: 12, color: AppTheme.info),
                      SizedBox(width: 4),
                      Text('Lampiran tersedia', style: TextStyle(fontSize: 11, color: AppTheme.info)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
