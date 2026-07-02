import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/siswa_provider.dart';

class LaporanHarianScreen extends StatefulWidget {
  const LaporanHarianScreen({super.key});

  @override
  State<LaporanHarianScreen> createState() => _LaporanHarianScreenState();
}

class _LaporanHarianScreenState extends State<LaporanHarianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kegiatanController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void dispose() {
    _kegiatanController.dispose();
    super.dispose();
  }

  void _pickDocumentation() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih file: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _submitLaporan() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SiswaProvider>(context, listen: false);
      final success = await provider.kirimLaporan(
        kegiatan: _kegiatanController.text.trim(),
        lampiranPath: _selectedFilePath,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laporan harian berhasil dikirim!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _kegiatanController.clear();

          setState(() {
            _selectedFilePath = null;
            _selectedFileName = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.error ?? 'Gagal mengirim laporan harian',
              ),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SiswaProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Harian'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.edit_note_rounded),
                text: 'Isi Laporan',
              ),
              Tab(
                icon: Icon(Icons.history_rounded),
                text: 'Riwayat Laporan',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: AppTheme.borderSoft,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Silakan isi laporan kegiatan Anda untuk tanggal ${DateFormat("d MMMM yyyy", "id_ID").format(DateTime.now())}.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Kegiatan Magang Hari Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _kegiatanController,
                      maxLines: 6,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText:
                            'Tuliskan deskripsi lengkap pekerjaan, project, atau materi yang Anda pelajari hari ini...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Deskripsi kegiatan tidak boleh kosong';
                        }

                        if (value.trim().length < 15) {
                          return 'Harap jelaskan kegiatan minimal 15 karakter';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Dokumentasi Kegiatan (Opsional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: _pickDocumentation,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.borderSoft,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pilih Berkas Dokumentasi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Format: JPG, PNG, atau PDF (Maks. 5MB)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (_selectedFileName != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.attachment,
                                      size: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedFileName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedFilePath = null;
                                          _selectedFileName = null;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: AppTheme.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    provider.loadingLaporan
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : ElevatedButton(
                            onPressed: _submitLaporan,
                            child: const Text('KIRIM LAPORAN'),
                          ),
                  ],
                ),
              ),
            ),

            _buildRiwayatTab(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTab(SiswaProvider provider) {
    if (provider.riwayatLaporan.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada laporan harian.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.riwayatLaporan.length,
      itemBuilder: (context, index) {
        final laporan = provider.riwayatLaporan[index];

        Color statusColor = AppTheme.warning;

        if (laporan.status == 'Disetujui') {
          statusColor = AppTheme.success;
        }

        if (laporan.status == 'Ditolak') {
          statusColor = AppTheme.danger;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                        'id_ID',
                      ).format(laporan.tanggal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        laporan.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  laporan.kegiatan,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),

                if (laporan.dokumentasiUrl != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lampiran tersedia (Tap untuk melihat)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ],

                if (laporan.catatanPembimbing != null &&
                    laporan.catatanPembimbing!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.borderSoft,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catatan Pembimbing:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          laporan.catatanPembimbing!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
}