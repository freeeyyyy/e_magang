import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';
import 'package:emagang_app/data/datasources/shared_data_store.dart';

class DaftarSiswaScreen extends StatefulWidget {
  const DaftarSiswaScreen({super.key});

  @override
  State<DaftarSiswaScreen> createState() => _DaftarSiswaScreenState();
}

class _DaftarSiswaScreenState extends State<DaftarSiswaScreen> {
  @override
  void initState() {
    super.initState();
    // Memuat data terupdate dari API Server
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadData();
    });
  }

  void _showAddSiswaDialog(BuildContext context, AdminProvider admin) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nisCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    final companyCtrl = TextEditingController(text: SharedDataStore.perusahaan);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Tambah Siswa Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Siswa', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) => v == null || !v.contains('@') ? 'Format email salah' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password Akun', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nisCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nomor Induk Siswa (NIS)', prefixIcon: Icon(Icons.badge_outlined)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'NIS wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: schoolCtrl,
                        decoration: const InputDecoration(labelText: 'Asal Sekolah (SMK)', prefixIcon: Icon(Icons.school_outlined)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Asal sekolah wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: companyCtrl,
                        decoration: const InputDecoration(labelText: 'Tempat Magang', prefixIcon: Icon(Icons.business_outlined)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Tempat magang wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Tutup dialog
                      Navigator.pop(ctx);

                      // Tampilkan loading di layar utama
                      final success = await admin.tambahSiswa(
                        nama: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text,
                        nis: nisCtrl.text.trim(),
                        sekolah: schoolCtrl.text.trim(),
                        tempatMagang: companyCtrl.text.trim(),
                      );

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Siswa ${nameCtrl.text} berhasil ditambahkan!\nAkun Ortu: ortu_${nisCtrl.text.trim()}@emagang.id'),
                            backgroundColor: AppTheme.success,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(admin.error ?? 'Gagal menambahkan siswa.'),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tambah Siswa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddSiswaDialog(context, admin),
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
                      : RefreshIndicator(
                          onRefresh: () => admin.loadData(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: admin.filteredSiswa.length,
                            itemBuilder: (ctx, i) {
                              final siswa = admin.filteredSiswa[i];
                              return _buildSiswaCard(context, siswa);
                            },
                          ),
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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            siswa.tempatMagang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
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
