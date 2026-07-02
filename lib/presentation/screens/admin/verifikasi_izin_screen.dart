import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';
import 'package:emagang_app/data/models/izin_model.dart';

class VerifikasiIzinScreen extends StatefulWidget {
  const VerifikasiIzinScreen({super.key});

  @override
  State<VerifikasiIzinScreen> createState() => _VerifikasiIzinScreenState();
}

class _VerifikasiIzinScreenState extends State<VerifikasiIzinScreen>
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
    required String izinId,
    required String namaSiswa,
    required String tipe,
    required String keterangan,
  }) async {
    String pilihan = 'Disetujui';

    await showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                tipe == 'Sakit' ? Icons.medical_services_rounded : Icons.assignment_late_rounded,
                color: tipe == 'Sakit' ? AppTheme.danger : AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Verifikasi $tipe', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.lightBg, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(keterangan, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
            ],
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
                final ok = await admin.verifikasiIzin(
                  siswaId: siswaId,
                  izinId: izinId,
                  status: pilihan,
                );
                if (ok && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Pengajuan $tipe berhasil di-$pilihan.'),
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
    final admin   = Provider.of<AdminProvider>(context);
    final semua   = admin.semuaIzin;
    final pending  = semua.where((m) => (m['izin'] as IzinModel).status == 'Pending').toList();
    final approved = semua.where((m) => (m['izin'] as IzinModel).status == 'Disetujui').toList();
    final rejected = semua.where((m) => (m['izin'] as IzinModel).status == 'Ditolak').toList();

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Verifikasi Izin & Sakit'),
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
          _buildIzinList(context, pending, admin, showActions: true),
          _buildIzinList(context, approved, admin, showActions: false),
          _buildIzinList(context, rejected, admin, showActions: false),
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

  Widget _buildIzinList(BuildContext context, List<Map<String, dynamic>> list, AdminProvider admin, {required bool showActions}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.medical_services_outlined, size: 60, color: AppTheme.borderSoft),
            SizedBox(height: 12),
            Text('Tidak ada pengajuan izin/sakit.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final siswa = list[i]['siswa'] as SiswaAdminData;
        final izin  = list[i]['izin'] as IzinModel;

        final isSakit  = izin.tipe == 'Sakit';
        final tipeColor = isSakit ? AppTheme.danger : AppTheme.warning;
        final tipeIcon  = isSakit ? Icons.medical_services_rounded : Icons.assignment_late_rounded;

        Color statusColor = AppTheme.warning;
        if (izin.status == 'Disetujui') statusColor = AppTheme.success;
        if (izin.status == 'Ditolak')   statusColor = AppTheme.danger;

        final durasi = izin.tanggalSelesai.difference(izin.tanggalMulai).inDays + 1;

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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tipeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tipeIcon, color: tipeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tipeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(izin.tipe, style: TextStyle(color: tipeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          Text(siswa.nis, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(izin.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tanggal & Durasi
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('d MMM yyyy', 'id_ID').format(izin.tanggalMulai)} – ${DateFormat('d MMM yyyy', 'id_ID').format(izin.tanggalSelesai)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.lightBg, borderRadius: BorderRadius.circular(8)),
                      child: Text('$durasi hari', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Keterangan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.lightBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(izin.keterangan, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                ),

                // Lampiran
                if (izin.lampiranUrl != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 14, color: AppTheme.info),
                      const SizedBox(width: 4),
                      Text(
                        isSakit ? 'Surat keterangan dokter tersedia' : 'Lampiran tersedia',
                        style: const TextStyle(fontSize: 12, color: AppTheme.info),
                      ),
                    ],
                  ),
                ],

                // Tanggal pengajuan
                const SizedBox(height: 4),
                Text(
                  'Diajukan: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(izin.diajukanPada)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),

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
                            izinId: izin.id,
                            namaSiswa: siswa.nama,
                            tipe: izin.tipe,
                            keterangan: izin.keterangan,
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
                            final ok = await admin.verifikasiIzin(
                              siswaId: siswa.id,
                              izinId: izin.id,
                              status: 'Disetujui',
                            );
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Pengajuan ${izin.tipe} berhasil disetujui.'),
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
