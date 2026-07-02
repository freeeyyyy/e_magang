import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/data/datasources/shared_data_store.dart';
import 'package:emagang_app/data/models/sertifikat_model.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';

class ManajemenSertifikatScreen extends StatelessWidget {
  const ManajemenSertifikatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final store = SharedDataStore.instance;
    final allSert = store.getAllSertifikat();

    // Gabungkan dengan data siswa
    final items = allSert.map((entry) {
      final siswa = admin.daftarSiswa.where((s) => s.id == entry.key).firstOrNull;
      return {'siswa': siswa, 'sertifikat': entry.value};
    }).where((m) => m['siswa'] != null).toList();

    // Sort: Menunggu Review dulu
    items.sort((a, b) {
      final order = {'Menunggu Review': 0, 'Sedang Diproses': 1, 'Tersedia': 2, 'Ditolak': 3};
      final sa = (a['sertifikat'] as SertifikatModel).status;
      final sb = (b['sertifikat'] as SertifikatModel).status;
      return (order[sa] ?? 99).compareTo(order[sb] ?? 99);
    });

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Manajemen Sertifikat'),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada pengajuan sertifikat.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                  const SizedBox(height: 8),
                  const Text('Pengajuan dari siswa akan muncul di sini.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final siswa = items[i]['siswa'] as SiswaAdminData;
                final sert = items[i]['sertifikat'] as SertifikatModel;
                return _buildSertifikatCard(context, siswa, sert, admin, store);
              },
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Menunggu Review':  return AppTheme.warning;
      case 'Sedang Diproses':  return AppTheme.info;
      case 'Tersedia':         return AppTheme.success;
      case 'Ditolak':          return AppTheme.danger;
      default:                 return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Menunggu Review':  return Icons.hourglass_empty_rounded;
      case 'Sedang Diproses':  return Icons.settings_rounded;
      case 'Tersedia':         return Icons.workspace_premium_rounded;
      case 'Ditolak':          return Icons.cancel_rounded;
      default:                 return Icons.help_outline;
    }
  }

  Widget _buildSertifikatCard(
    BuildContext context,
    SiswaAdminData siswa,
    SertifikatModel sert,
    AdminProvider admin,
    SharedDataStore store,
  ) {
    final color = _statusColor(sert.status);
    final icon = _statusIcon(sert.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header siswa
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(siswa.nama[0],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(siswa.nama,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Text('NIS: ${siswa.nis}  •  ${siswa.sekolah}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(sert.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Timeline
            _buildTimeline(sert),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progressValue(sert.status),
                minHeight: 6,
                backgroundColor: AppTheme.borderSoft,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _progressLabel(sert.status),
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(context, siswa, sert, admin, store),
          ],
        ),
      ),
    );
  }

  double _progressValue(String status) {
    switch (status) {
      case 'Menunggu Review':  return 0.33;
      case 'Sedang Diproses':  return 0.66;
      case 'Tersedia':         return 1.0;
      case 'Ditolak':          return 0.0;
      default:                 return 0.0;
    }
  }

  String _progressLabel(String status) {
    switch (status) {
      case 'Menunggu Review':  return 'Menunggu ditinjau admin (1/3)';
      case 'Sedang Diproses':  return 'Sertifikat sedang disiapkan (2/3)';
      case 'Tersedia':         return 'Sertifikat siap diunduh siswa (3/3) ✓';
      case 'Ditolak':          return 'Pengajuan ditolak';
      default:                 return '';
    }
  }

  Widget _buildTimeline(SertifikatModel sert) {
    final steps = [
      {'label': 'Diajukan', 'time': sert.diajukanPada, 'done': true},
      {'label': 'Diproses', 'time': sert.diprosesPada, 'done': sert.diprosesPada != null},
      {'label': 'Diterbitkan', 'time': sert.disetujuiPada, 'done': sert.disetujuiPada != null},
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isDone = step['done'] as bool;
        final time = step['time'] as DateTime?;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? AppTheme.success : AppTheme.borderSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : Icons.circle_outlined,
                        size: 16, color: isDone ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(step['label'] as String,
                        style: TextStyle(fontSize: 10, color: isDone ? AppTheme.success : AppTheme.textSecondary,
                            fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
                    if (time != null)
                      Text(DateFormat('d/M HH:mm').format(time),
                          style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 28),
                    color: isDone ? AppTheme.success.withOpacity(0.4) : AppTheme.borderSoft,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    SiswaAdminData siswa,
    SertifikatModel sert,
    AdminProvider admin,
    SharedDataStore store,
  ) {
    if (sert.status == 'Tersedia') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
            const SizedBox(width: 8),
            const Text('Sertifikat telah diterbitkan dan tersedia untuk diunduh siswa.',
                style: TextStyle(fontSize: 12, color: AppTheme.success)),
          ],
        ),
      );
    }

    if (sert.status == 'Ditolak') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 18),
            SizedBox(width: 8),
            Text('Pengajuan telah ditolak.', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (sert.status == 'Menunggu Review') ...[
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.danger),
              label: const Text('Tolak', style: TextStyle(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                store.updateStatusSertifikat(siswa.id, 'Ditolak');
                admin.notifyDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Pengajuan sertifikat ditolak.'),
                  backgroundColor: AppTheme.danger,
                ));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Proses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.info,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                store.updateStatusSertifikat(siswa.id, 'Sedang Diproses');
                admin.notifyDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Pengajuan ${siswa.nama} sedang diproses.'),
                  backgroundColor: AppTheme.info,
                ));
              },
            ),
          ),
        ],
        if (sert.status == 'Sedang Diproses')
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.workspace_premium_rounded, size: 16),
              label: const Text('Terbitkan Sertifikat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showTerbitkanDialog(context, siswa, store, admin),
            ),
          ),
      ],
    );
  }

  void _showTerbitkanDialog(
    BuildContext context,
    SiswaAdminData siswa,
    SharedDataStore store,
    AdminProvider admin,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppTheme.success),
            SizedBox(width: 8),
            Text('Terbitkan Sertifikat', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Konfirmasi penerbitan sertifikat magang untuk ${siswa.nama}?\n\n'
          'Setelah diterbitkan, siswa dapat mengunduh sertifikat dari dashboard mereka.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              store.updateStatusSertifikat(
                siswa.id, 'Tersedia',
                downloadUrl: 'https://emagang.astronet.id/sertifikat/${siswa.nama.toLowerCase().replaceAll(' ', '-')}-2024.pdf',
              );
              admin.notifyDataChanged();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Sertifikat ${siswa.nama} berhasil diterbitkan! ✓'),
                backgroundColor: AppTheme.success,
              ));
            },
            child: const Text('Ya, Terbitkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
