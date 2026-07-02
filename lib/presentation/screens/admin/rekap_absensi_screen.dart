import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/admin_provider.dart';
import 'package:emagang_app/data/models/absensi_model.dart';

class RekapAbsensiScreen extends StatefulWidget {
  const RekapAbsensiScreen({super.key});

  @override
  State<RekapAbsensiScreen> createState() => _RekapAbsensiScreenState();
}

class _RekapAbsensiScreenState extends State<RekapAbsensiScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hadir':       return AppTheme.success;
      case 'Terlambat':   return AppTheme.warning;
      case 'Izin':        return AppTheme.info;
      case 'Alpa':        return AppTheme.danger;
      default:            return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Hadir':       return Icons.check_circle_rounded;
      case 'Terlambat':   return Icons.schedule_rounded;
      case 'Izin':        return Icons.medical_services_rounded;
      case 'Alpa':        return Icons.cancel_rounded;
      default:            return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final absensiList = admin.getAbsensiByTanggal(_selectedDate);

    final hadirCount  = absensiList.where((m) => (m['absensi'] as AbsensiModel).statusMasuk == 'Hadir').length;
    final terlambatCount = absensiList.where((m) => (m['absensi'] as AbsensiModel).statusMasuk == 'Terlambat').length;
    final izinCount   = absensiList.where((m) => (m['absensi'] as AbsensiModel).statusMasuk == 'Izin').length;
    final alpaCount   = absensiList.where((m) => (m['absensi'] as AbsensiModel).statusMasuk == 'Alpa').length;

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Rekap Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Pilih Tanggal',
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector Banner
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Dipilih', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_rounded, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),

          // Summary Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSummaryChip('Hadir', hadirCount, AppTheme.success),
                const SizedBox(width: 8),
                _buildSummaryChip('Terlambat', terlambatCount, AppTheme.warning),
                const SizedBox(width: 8),
                _buildSummaryChip('Izin', izinCount, AppTheme.info),
                const SizedBox(width: 8),
                _buildSummaryChip('Alpa', alpaCount, AppTheme.danger),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: absensiList.isEmpty
                ? const Center(child: Text('Tidak ada data absensi.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: absensiList.length,
                    itemBuilder: (ctx, i) {
                      final siswa = absensiList[i]['siswa'] as SiswaAdminData;
                      final absen = absensiList[i]['absensi'] as AbsensiModel;
                      return _buildAbsensiRow(siswa, absen);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsensiRow(SiswaAdminData siswa, AbsensiModel absen) {
    final color = _statusColor(absen.statusMasuk);
    final icon  = _statusIcon(absen.statusMasuk);

    String masukStr  = absen.waktuMasuk  != null ? DateFormat('HH:mm').format(absen.waktuMasuk!)  : '--:--';
    String keluarStr = absen.waktuKeluar != null ? DateFormat('HH:mm').format(absen.waktuKeluar!) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          // Avatar + status icon
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Text(
                  siswa.nama[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.5)),
                  child: Icon(icon, size: 10, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(siswa.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                Text(siswa.nis, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  absen.statusMasuk,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$masukStr → $keluarStr',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
