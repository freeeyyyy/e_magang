import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:emagang_app/core/theme/app_theme.dart';
import 'package:emagang_app/presentation/providers/siswa_provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isScanMasuk = true; // true = Masuk, false = Pulang
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrCode = barcodes.first.rawValue;
    if (qrCode == null || qrCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    _processQrCode(qrCode);
  }

  void _processQrCode(String code) async {
    final siswaProvider = Provider.of<SiswaProvider>(context, listen: false);
    
    // In a real app we might get the user's GPS coordinates.
    // For demo, we supply mock coordinates.
    const String mockLokasi = '-6.2088, 106.8456 (PT Solusi Teknologi)';

    siswaProvider.clearError();

    dynamic result;
    if (_isScanMasuk) {
      result = await siswaProvider.checkIn(qrCode: code, lokasi: mockLokasi);
    } else {
      result = await siswaProvider.checkOut(qrCode: code, lokasi: mockLokasi);
    }

    if (mounted) {
      if (result != null) {
        // Show Success Dialog
        _showResultDialog(
          title: 'Absensi Berhasil!',
          message: 'Absensi ${_isScanMasuk ? "Masuk" : "Pulang"} Anda berhasil dicatat.\nWaktu: ${DateTime.now().hour}:${DateTime.now().minute} WIB',
          isSuccess: true,
        );
      } else {
        // Show Error Dialog
        _showResultDialog(
          title: 'Absensi Gagal!',
          message: siswaProvider.error ?? 'Terjadi kesalahan tidak dikenal saat absensi.',
          isSuccess: false,
        );
      }
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess ? AppTheme.success : AppTheme.danger,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSuccess ? AppTheme.success : AppTheme.danger)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? AppTheme.success : AppTheme.primaryColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                context.pop(); // Go back to dashboard
              } else {
                setState(() {
                  _isProcessing = false;
                });
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Demonstration helper: triggers check-in/out with simulated fresh or expired tokens
  void _triggerSimulatedScan(bool makeExpired) {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    final int offset = makeExpired ? -15000 : 0; // -15 seconds = already expired
    final int timestamp = DateTime.now().millisecondsSinceEpoch + offset;
    
    final String typePrefix = _isScanMasuk ? 'emagang-in-' : 'emagang-out-';
    final String generatedQrCode = '$typePrefix$timestamp';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          makeExpired 
              ? 'Menstimulasi Scan QR Code Kadaluwarsa (dibuat 15 detik lalu)...' 
              : 'Menstimulasi Scan QR Code Valid (berlaku 10 detik)...'
        ),
        duration: const Duration(milliseconds: 1500),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _processQrCode(generatedQrCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai QR Absensi'),
      ),
      body: Stack(
        children: [
          // 1. Camera QR Scanner
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // 2. Scan overlay border UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentColor, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Posisikan QR di dalam kotak',
                    style: TextStyle(color: Colors.white, fontSize: 12, backgroundColor: Colors.black54),
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Controller: Masuk vs Pulang selector
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isScanMasuk = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isScanMasuk ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Absen Masuk',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isScanMasuk = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isScanMasuk ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Absen Pulang',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Controls: Flash/Switch and Simulator buttons
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Camera Actions (Flashlight, Camera Swap)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () => _cameraController.toggleTorch(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                        onPressed: () => _cameraController.switchCamera(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Simulator Panel
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Simulasi Pemindaian QR (Untuk Pengujian)',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _triggerSimulatedScan(false),
                              child: const Text('QR Valid (10s)', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _triggerSimulatedScan(true),
                              child: const Text('QR Kadaluwarsa', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
