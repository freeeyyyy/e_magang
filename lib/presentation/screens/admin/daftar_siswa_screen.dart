import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';

class DaftarSiswaScreen extends StatelessWidget {
  const DaftarSiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Daftar Siswa Magang'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (val) => admin.setFilterStatus(val),
            itemBuilder: (_) => ['Semua', 'Aktif', 'Selesai']
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
          ),
        ],
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Chips
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: ['Semua', 'Aktif', 'Selesai'].map((s) {
                      final selected = admin.filterStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s),
                          selected: selected,
                          onSelected: (_) => admin.setFilterStatus(s),
                          selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                          checkmarkColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // List Siswa
                Expanded(
                  child: admin.filteredSiswa.isEmpty
                      ? const Center(
                          child: Text('Tidak ada data siswa.', style: TextStyle(color: AppTheme.textSecondary)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: admin.filteredSiswa.length,
                          itemBuilder: (ctx, i) {
                            final siswa = admin.filteredSiswa[i];
                            return _buildSiswaCard(context, siswa);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSiswaCard(BuildContext context, SiswaAdminData siswa) {
    final isAktif = siswa.status == 'Aktif';
    final progress = siswa.progressMagang;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => context.push('/admin/siswa/${siswa.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isAktif
                        ? AppTheme.primaryColor.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    child: Text(
                      siswa.nama[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isAktif ? AppTheme.primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siswa.nama,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'NIS: ${siswa.nis}  •  ${siswa.sekolah}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAktif ? AppTheme.success.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      siswa.status,
                      style: TextStyle(
                        color: isAktif ? AppTheme.success : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stats Row
              Row(
                children: [
                  _buildMiniStat('Hadir', '${siswa.totalHadir}', AppTheme.success),
                  const SizedBox(width: 12),
                  _buildMiniStat('Alpa', '${siswa.totalAlpa}', AppTheme.danger),
                  const SizedBox(width: 12),
                  _buildMiniStat('Izin', '${siswa.totalIzin}', AppTheme.warning),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.borderSoft,
                  color: isAktif ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        siswa.tempatMagang,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Detail',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primaryColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label: $val', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
