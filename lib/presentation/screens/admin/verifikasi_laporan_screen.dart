import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';
import 'package:emagang_app/data/models/laporan_model.dart';

class VerifikasiLaporanScreen extends StatefulWidget {
  const VerifikasiLaporanScreen({super.key});

  @override
  State<VerifikasiLaporanScreen> createState() => _VerifikasiLaporanScreenState();
}

class _VerifikasiLaporanScreenState extends State<VerifikasiLaporanScreen>
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

  Future<void> _showVerifikasiDialog({
    required BuildContext ctx,
    required AdminProvider admin,
    required String siswaId,
    required String laporanId,
    required String namaSiswa,
    required String kegiatan,
  }) async {
    final catatanCtrl = TextEditingController();
    String pilihan = 'Disetujui';

    await showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Expanded(child: Text('Verifikasi Laporan', style: TextStyle(fontSize: 16))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(kegiatan, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Keputusan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: ['Disetujui', 'Ditolak'].map((val) {
                    final isSelected = pilihan == val;
                    final color = val == 'Disetujui' ? AppTheme.success : AppTheme.danger;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setDialogState(() => pilihan = val),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.12) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? color : AppTheme.borderSoft, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  val == 'Disetujui' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: isSelected ? color : AppTheme.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(val, style: TextStyle(
                                  color: isSelected ? color : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Catatan Pembimbing (opsional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    hintText: 'Masukkan catatan atau komentar...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pilihan == 'Disetujui' ? AppTheme.success : AppTheme.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final ok = await admin.verifikasiLaporan(
                  siswaId: siswaId,
                  laporanId: laporanId,
                  status: pilihan,
                  catatan: catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
                );
                if (ok && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Laporan berhasil di-$pilihan.'),
                    backgroundColor: pilihan == 'Disetujui' ? AppTheme.success : AppTheme.danger,
                  ));
                }
              },
              child: Text(pilihan, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final semua    = admin.semuaLaporan;
    final pending  = semua.where((m) => (m['laporan'] as LaporanModel).status == 'Pending').toList();
    final approved = semua.where((m) => (m['laporan'] as LaporanModel).status == 'Disetujui').toList();
    final rejected = semua.where((m) => (m['laporan'] as LaporanModel).status == 'Ditolak').toList();

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Verifikasi Laporan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: _buildTabLabel('Pending', pending.length, AppTheme.warning)),
            Tab(child: _buildTabLabel('Disetujui', approved.length, AppTheme.success)),
            Tab(child: _buildTabLabel('Ditolak', rejected.length, AppTheme.danger)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLaporanList(context, pending, admin, showActions: true),
          _buildLaporanList(context, approved, admin, showActions: false),
          _buildLaporanList(context, rejected, admin, showActions: false),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildLaporanList(BuildContext context, List<Map<String, dynamic>> list, AdminProvider admin, {required bool showActions}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.article_outlined, size: 60, color: AppTheme.borderSoft),
            SizedBox(height: 12),
            Text('Tidak ada laporan.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final siswa   = list[i]['siswa'] as SiswaAdminData;
        final laporan = list[i]['laporan'] as LaporanModel;

        Color statusColor = AppTheme.warning;
        if (laporan.status == 'Disetujui') statusColor = AppTheme.success;
        if (laporan.status == 'Ditolak')   statusColor = AppTheme.danger;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(siswa.nama[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                          Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(laporan.tanggal),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(laporan.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Kegiatan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(laporan.kegiatan, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                ),
                // Catatan
                if (laporan.catatanPembimbing != null && laporan.catatanPembimbing!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.comment_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Catatan: ${laporan.catatanPembimbing}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
                // Lampiran
                if (laporan.dokumentasiUrl != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 14, color: AppTheme.info),
                      const SizedBox(width: 4),
                      Text('Ada lampiran dokumen', style: const TextStyle(fontSize: 12, color: AppTheme.info)),
                    ],
                  ),
                ],
                // Action Buttons
                if (showActions) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.danger),
                          label: const Text('Tolak', style: TextStyle(color: AppTheme.danger)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.danger),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showVerifikasiDialog(
                            ctx: context,
                            admin: admin,
                            siswaId: siswa.id,
                            laporanId: laporan.id,
                            namaSiswa: siswa.nama,
                            kegiatan: laporan.kegiatan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: const Text('Setujui'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final ok = await admin.verifikasiLaporan(
                              siswaId: siswa.id,
                              laporanId: laporan.id,
                              status: 'Disetujui',
                            );
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Laporan berhasil disetujui.'),
                                backgroundColor: AppTheme.success,
                              ));
                            }
                          },
                        ),
                      ),
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
