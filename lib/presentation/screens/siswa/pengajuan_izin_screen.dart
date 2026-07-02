import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/siswa_provider.dart';

class PengajuanIzinScreen extends StatefulWidget {
  const PengajuanIzinScreen({super.key});

  @override
  State<PengajuanIzinScreen> createState() => _PengajuanIzinScreenState();
}

class _PengajuanIzinScreenState extends State<PengajuanIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  
  String _selectedTipe = 'Izin';
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDateRange: _tanggalMulai != null && _tanggalSelesai != null
          ? DateTimeRange(start: _tanggalMulai!, end: _tanggalSelesai!)
          : null,
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _tanggalMulai = picked.start;
        _tanggalSelesai = picked.end;
      });
    }
  }

  void _pickAttachment() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih berkas: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _submitIzin() async {
    if (_tanggalMulai == null || _tanggalSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rentang tanggal izin terlebih dahulu!'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SiswaProvider>(context, listen: false);
      final success = await provider.kirimIzin(
        tanggalMulai: _tanggalMulai!,
        tanggalSelesai: _tanggalSelesai!,
        tipe: _selectedTipe,
        keterangan: _keteranganController.text.trim(),
        lampiranPath: _selectedFilePath,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan izin/sakit berhasil dikirim!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Clear inputs
          _keteranganController.clear();
          setState(() {
            _tanggalMulai = null;
            _tanggalSelesai = null;
            _selectedFilePath = null;
            _selectedFileName = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Gagal memproses pengajuan izin'),
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
          title: const Text('Pengajuan Izin / Sakit'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.note_add_outlined), text: 'Buat Pengajuan'),
              Tab(icon: Icon(Icons.history_toggle_off_rounded), text: 'Riwayat Pengajuan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Form
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tipe Izin
                    const Text(
                      'Pilih Jenis Pengajuan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTipe,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.label_important_outline, color: AppTheme.textSecondary),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Izin', child: Text('Izin Kegiatan')),
                        DropdownMenuItem(value: 'Sakit', child: Text('Sakit (Butuh Istirahat)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTipe = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Trigger
                    const Text(
                      'Pilih Rentang Tanggal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSoft, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                                const SizedBox(width: 12),
                                Text(
                                  _tanggalMulai == null
                                      ? 'Pilih Tanggal Mulai s/d Selesai'
                                      : '${DateFormat("dd/MM/yyyy").format(_tanggalMulai!)} - ${DateFormat("dd/MM/yyyy").format(_tanggalSelesai!)}',
                                  style: TextStyle(
                                    color: _tanggalMulai == null ? Colors.grey : AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Keterangan
                    const Text(
                      'Alasan / Keterangan Tambahan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan alasan pengajuan Anda secara detail dan jelas...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Keterangan tidak boleh kosong';
                        }
                        if (value.trim().length < 10) {
                          return 'Berikan alasan yang lebih detail (Min. 10 karakter)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lampiran Bukti File
                    Text(
                      _selectedTipe == 'Sakit' ? 'Unggah Surat Keterangan Dokter' : 'Unggah Surat Pernyataan / Lampiran',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTipe == 'Sakit' 
                          ? '*Wajib untuk sakit > 1 hari' 
                          : '*Opsional, melancarkan proses persetujuan',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppTheme.accentColor, width: 1.5),
                      ),
                      icon: const Icon(Icons.file_present_rounded, color: AppTheme.accentColor),
                      label: const Text('PILIH DOKUMEN / GAMBAR', style: TextStyle(color: AppTheme.accentColor)),
                      onPressed: _pickAttachment,
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check, color: AppTheme.success, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFileName!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilePath = null;
                                  _selectedFileName = null;
                                });
                              },
                              child: const Icon(Icons.close, size: 16, color: AppTheme.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),

                    // Submit Button
                    provider.loadingIzin
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitIzin,
                            child: const Text('KIRIM PENGAJUAN'),
                          ),
                  ],
                ),
              ),
            ),

            // Tab 2: History
            _buildRiwayatIzinTab(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatIzinTab(SiswaProvider provider) {
    if (provider.riwayatIzin.isEmpty) {
      return const Center(
        child: Text('Belum ada pengajuan izin/sakit.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.riwayatIzin.length,
      itemBuilder: (context, index) {
        final izin = provider.riwayatIzin[index];
        
        Color statusColor = AppTheme.warning;
        if (izin.status == 'Disetujui') statusColor = AppTheme.success;
        if (izin.status == 'Ditolak') statusColor = AppTheme.danger;

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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: izin.tipe == 'Sakit' ? AppTheme.danger.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                          child: Icon(
                            izin.tipe == 'Sakit' ? Icons.sick : Icons.assignment,
                            size: 14,
                            color: izin.tipe == 'Sakit' ? AppTheme.danger : AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          izin.tipe,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                const SizedBox(height: 12),
                Text(
                  'Tanggal: ${DateFormat("dd MMM").format(izin.tanggalMulai)} s/d ${DateFormat("dd MMM yyyy").format(izin.tanggalSelesai)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  izin.keterangan,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                if (izin.catatan != null && izin.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Tanggapan: ${izin.catatan}',
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
}