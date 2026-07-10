const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('./database');

const app = express();
const PORT = 3000;
const JWT_SECRET = 'super_secret_key_emagang_app';

app.use(cors());
app.use(express.json());

// Request Logger - log semua request yang masuk
app.use((req, res, next) => {
  const timestamp = new Date().toISOString().split('T')[1].split('.')[0];
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// Welcome route untuk mengecek status server di browser
app.get('/', (req, res) => {
  res.send('<h1>API E-Magang Berhasil Berjalan! 🚀</h1><p>Gunakan aplikasi mobile untuk mengakses fitur-fitur.</p>');
});

// Logout endpoint (stateless JWT - cukup respond OK)
app.post('/api/auth/logout', (req, res) => {
  res.json({ message: 'Logout berhasil' });
});

// Middleware Autentikasi
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ message: 'Token tidak tersedia' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Token tidak valid/kadaluwarsa' });
    req.user = user;
    next();
  });
}

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email dan password harus diisi' });
  }

  db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
    if (err) return res.status(500).json({ message: err.message });
    if (!user) return res.status(400).json({ message: 'Akun tidak ditemukan' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: 'Password salah' });

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, nama: user.nama, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Ambil data tambahan anak jika ortu
    if (user.role === 'ortu') {
      db.get('SELECT * FROM users WHERE id = ?', [user.id_anak], (err, anak) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json({
          token,
          user: {
            id: user.id,
            nama: user.nama,
            email: user.email,
            role: user.role,
            idAnak: user.id_anak,
            namaAnak: anak ? anak.nama : null,
            nisAnak: anak ? anak.nis : null
          }
        });
      });
    } else {
      res.json({
        token,
        user: {
          id: user.id,
          nama: user.nama,
          email: user.email,
          role: user.role,
          nis: user.nis,
          sekolah: user.sekolah,
          tempatMagang: user.tempat_magang
        }
      });
    }
  });
});

// Profile API
app.get('/api/auth/profile', authenticateToken, (req, res) => {
  db.get('SELECT id, nama, email, role, nis, sekolah, tempat_magang, id_anak FROM users WHERE id = ?', [req.user.id], (err, user) => {
    if (err) return res.status(500).json({ message: err.message });
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    if (user.role === 'ortu') {
      db.get('SELECT * FROM users WHERE id = ?', [user.id_anak], (err, anak) => {
        res.json({
          user: {
            ...user,
            namaAnak: anak ? anak.nama : null,
            nisAnak: anak ? anak.nis : null
          }
        });
      });
    } else {
      res.json({ user });
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// SISWA APIs
// ─────────────────────────────────────────────────────────────────────────────

// Get Riwayat Absensi
app.get('/api/siswa/absensi/riwayat', authenticateToken, (req, res) => {
  db.all('SELECT * FROM absensi WHERE user_id = ? ORDER BY tanggal DESC', [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(rows);
  });
});

// Check-In QR
app.post('/api/siswa/absensi/check-in', authenticateToken, (req, res) => {
  const { qr_code, lokasi } = req.body;

  if (!qr_code.startsWith('emagang-in-')) {
    return res.status(400).json({ message: 'Format QR Code tidak valid!' });
  }

  const timePart = qr_code.replaceFirst ? qr_code.replaceFirst('emagang-in-', '') : qr_code.replace('emagang-in-', '');
  const timestamp = parseInt(timePart, 10);
  if (isNaN(timestamp) || Math.abs(Date.now() - timestamp) > 15000) {
    return res.status(400).json({ message: 'QR Code kedaluwarsa atau tidak valid!' });
  }

  const today = new Date().toISOString().split('T')[0];
  const now = new Date();
  const statusMasuk = now.getHours() >= 8 && now.getMinutes() > 0 ? 'Terlambat' : 'Hadir';

  // Hapus dulu record absensi hari ini jika ada
  db.run('DELETE FROM absensi WHERE user_id = ? AND tanggal = ?', [req.user.id, today], (err) => {
    if (err) return res.status(500).json({ message: err.message });

    const newAbsen = {
      id: `absen_${Date.now()}`,
      user_id: req.user.id,
      tanggal: today,
      waktu_masuk: now.toISOString(),
      waktu_keluar: null,
      status_masuk: statusMasuk,
      status_keluar: null,
      lokasi_masuk: lokasi,
      lokasi_keluar: null,
      is_valid: 1
    };

    db.run(`
      INSERT INTO absensi (id, user_id, tanggal, waktu_masuk, status_masuk, lokasi_masuk)
      VALUES (?, ?, ?, ?, ?, ?)
    `, [newAbsen.id, newAbsen.user_id, newAbsen.tanggal, newAbsen.waktu_masuk, newAbsen.status_masuk, newAbsen.lokasi_masuk], (err) => {
      if (err) return res.status(500).json({ message: err.message });
      res.json(newAbsen);
    });
  });
});

// Check-Out QR
app.post('/api/siswa/absensi/check-out', authenticateToken, (req, res) => {
  const { qr_code, lokasi } = req.body;

  if (!qr_code.startsWith('emagang-out-')) {
    return res.status(400).json({ message: 'Format QR Code tidak valid!' });
  }

  const today = new Date().toISOString().split('T')[0];
  const now = new Date();

  db.get('SELECT * FROM absensi WHERE user_id = ? AND tanggal = ?', [req.user.id, today], (err, row) => {
    if (err) return res.status(500).json({ message: err.message });

    if (row) {
      db.run(`
        UPDATE absensi
        SET waktu_keluar = ?, status_keluar = 'Hadir', lokasi_keluar = ?
        WHERE id = ?
      `, [now.toISOString(), lokasi, row.id], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json({
          ...row,
          waktu_keluar: now.toISOString(),
          status_keluar: 'Hadir',
          lokasi_keluar: lokasi
        });
      });
    } else {
      // Pulang tanpa absen masuk
      const newAbsen = {
        id: `absen_${Date.now()}`,
        user_id: req.user.id,
        tanggal: today,
        waktu_masuk: null,
        waktu_keluar: now.toISOString(),
        status_masuk: 'Alpa',
        status_keluar: 'Hadir',
        lokasi_masuk: null,
        lokasi_keluar: lokasi,
        is_valid: 1
      };

      db.run(`
        INSERT INTO absensi (id, user_id, tanggal, waktu_keluar, status_masuk, status_keluar, lokasi_keluar)
        VALUES (?, ?, ?, ?, 'Alpa', 'Hadir', ?)
      `, [newAbsen.id, newAbsen.user_id, newAbsen.tanggal, newAbsen.waktu_keluar, newAbsen.lokasi_keluar], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json(newAbsen);
      });
    }
  });
});

// Laporan Harian (GET & POST)
app.get('/api/siswa/laporan-harian', authenticateToken, (req, res) => {
  db.all('SELECT * FROM laporan WHERE user_id = ? ORDER BY tanggal DESC', [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(rows);
  });
});

app.post('/api/siswa/laporan-harian', authenticateToken, (req, res) => {
  const { kegiatan, tanggal } = req.body;
  const tgl = tanggal || new Date().toISOString().split('T')[0];

  const newLaporan = {
    id: `lap_${Date.now()}`,
    user_id: req.user.id,
    tanggal: tgl,
    kegiatan,
    status: 'Pending'
  };

  db.run(`
    INSERT INTO laporan (id, user_id, tanggal, kegiatan, status)
    VALUES (?, ?, ?, ?, 'Pending')
  `, [newLaporan.id, newLaporan.user_id, newLaporan.tanggal, newLaporan.kegiatan], (err) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(newLaporan);
  });
});

// Izin (GET & POST)
app.get('/api/siswa/izin', authenticateToken, (req, res) => {
  db.all('SELECT * FROM izin WHERE user_id = ? ORDER BY diajukan_pada DESC', [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(rows);
  });
});

app.post('/api/siswa/izin', authenticateToken, (req, res) => {
  const { tanggal_mulai, tanggal_selesai, tipe, keterangan } = req.body;

  const newIzin = {
    id: `izin_${Date.now()}`,
    user_id: req.user.id,
    tanggal_mulai,
    tanggal_selesai,
    tipe,
    keterangan,
    status: 'Pending',
    diajukan_pada: new Date().toISOString()
  };

  db.run(`
    INSERT INTO izin (id, user_id, tanggal_mulai, tanggal_selesai, tipe, keterangan, status, diajukan_pada)
    VALUES (?, ?, ?, ?, ?, ?, 'Pending', ?)
  `, [newIzin.id, newIzin.user_id, newIzin.tanggal_mulai, newIzin.tanggal_selesai, newIzin.tipe, newIzin.keterangan, newIzin.diajukan_pada], (err) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(newIzin);
  });
});

// Sertifikat (Request & Status)
app.post('/api/siswa/sertifikat/request', authenticateToken, (req, res) => {
  const today = new Date().toISOString();
  db.get('SELECT * FROM sertifikat WHERE user_id = ?', [req.user.id], (err, row) => {
    if (err) return res.status(500).json({ message: err.message });
    if (row) return res.status(400).json({ message: 'Sertifikat sudah pernah diajukan sebelumnya' });

    db.run(`
      INSERT INTO sertifikat (id, user_id, status, diajukan_pada)
      VALUES (?, ?, 'Menunggu Review', ?)
    `, [`sert_${Date.now()}`, req.user.id, today], (err) => {
      if (err) return res.status(500).json({ message: err.message });
      res.json({ success: true });
    });
  });
});

app.get('/api/siswa/sertifikat', authenticateToken, (req, res) => {
  db.get('SELECT * FROM sertifikat WHERE user_id = ?', [req.user.id], (err, row) => {
    if (err) return res.status(500).json({ message: err.message });

    if (!row) {
      // Hitung progres riil berdasarkan database absensi
      db.all('SELECT * FROM absensi WHERE user_id = ?', [req.user.id], (err, absensi) => {
        if (err) return res.status(500).json({ message: err.message });
        
        const total_hari = 90;
        const hari_terisi = absensi ? absensi.filter(a => a.status_masuk === 'Hadir' || a.status_masuk === 'Terlambat').length : 0;
        const progres = Math.min(1.0, hari_terisi / total_hari);

        return res.json({
          status: 'Belum Diajukan',
          progres,
          total_hari,
          hari_terisi,
          pesan: 'Anda bisa mengajukan sertifikat jika masa magang sudah selesai.'
        });
      });
      return;
    }

    let pesan = '';
    if (row.status === 'Menunggu Review') pesan = 'Pengajuan Anda telah diterima. Admin sedang meninjau kelengkapan dokumen.';
    else if (row.status === 'Sedang Diproses') pesan = 'Sertifikat Anda sedang disiapkan oleh admin. Harap tunggu beberapa saat.';
    else if (row.status === 'Tersedia') pesan = 'Selamat! Sertifikat magang Anda telah terbit dan siap diunduh.';
    else if (row.status === 'Ditolak') pesan = 'Pengajuan sertifikat ditolak. Silakan hubungi admin.';

    res.json({
      status: row.status,
      download_url: row.download_url,
      pesan
    });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// CHAT APIs
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/chats/:siswaId', authenticateToken, (req, res) => {
  db.all('SELECT * FROM chats WHERE siswa_id = ? ORDER BY timestamp ASC', [req.params.siswaId], (err, rows) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(rows);
  });
});

app.post('/api/chats', authenticateToken, (req, res) => {
  const { siswa_id, message, sender_role } = req.body;
  const newMsg = {
    id: `msg_${Date.now()}`,
    siswa_id,
    sender_id: req.user.id,
    sender_role,
    message,
    timestamp: new Date().toISOString(),
    is_read: 0
  };

  db.run(`
    INSERT INTO chats (id, siswa_id, sender_id, sender_role, message, timestamp, is_read)
    VALUES (?, ?, ?, ?, ?, ?, 0)
  `, [newMsg.id, newMsg.siswa_id, newMsg.sender_id, newMsg.sender_role, newMsg.message, newMsg.timestamp], (err) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json(newMsg);
  });
});

// Mark Read
app.post('/api/chats/:siswaId/read', authenticateToken, (req, res) => {
  const readerRole = req.user.role;
  // Jika pembaca adalah admin, tandai pesan dari siswa sebagai dibaca. Begitu juga sebaliknya.
  const targetSenderRole = readerRole === 'admin' ? 'siswa' : 'admin';

  db.run(`
    UPDATE chats
    SET is_read = 1
    WHERE siswa_id = ? AND sender_role = ?
  `, [req.params.siswaId, targetSenderRole], (err) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json({ success: true });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN & ORANG TUA MONITORING APIs
// ─────────────────────────────────────────────────────────────────────────────

// Ortu get anak data
app.get('/api/ortu/anak/:type/:idAnak', authenticateToken, (req, res) => {
  const { type, idAnak } = req.params;

  if (type === 'absensi') {
    db.all('SELECT * FROM absensi WHERE user_id = ? ORDER BY tanggal DESC', [idAnak], (err, rows) => {
      if (err) return res.status(500).json({ message: err.message });
      res.json(rows);
    });
  } else if (type === 'laporan') {
    db.all('SELECT * FROM laporan WHERE user_id = ? ORDER BY tanggal DESC', [idAnak], (err, rows) => {
      if (err) return res.status(500).json({ message: err.message });
      res.json(rows);
    });
  } else if (type === 'izin') {
    db.all('SELECT * FROM izin WHERE user_id = ? ORDER BY diajukan_pada DESC', [idAnak], (err, rows) => {
      if (err) return res.status(500).json({ message: err.message });
      res.json(rows);
    });
  } else {
    res.status(400).json({ message: 'Tipe monitoring tidak dikenal' });
  }
});

app.get('/api/ortu/monitoring/:idAnak/progres', authenticateToken, (req, res) => {
  const idAnak = req.params.idAnak;

  db.all('SELECT * FROM absensi WHERE user_id = ?', [idAnak], (err, absensi) => {
    if (err) return res.status(500).json({ message: err.message });

    db.all('SELECT * FROM laporan WHERE user_id = ?', [idAnak], (err, laporan) => {
      if (err) return res.status(500).json({ message: err.message });

      db.get('SELECT * FROM sertifikat WHERE user_id = ?', [idAnak], (err, sertifikat) => {
        if (err) return res.status(500).json({ message: err.message });

        const total_hari = 90;
        const hari_terisi = absensi.filter(a => a.status_masuk === 'Hadir' || a.status_masuk === 'Terlambat').length;
        const progres = Math.min(1.0, hari_terisi / total_hari);

        res.json({
          progres,
          total_hari,
          hari_terisi,
          total_laporan: laporan.length,
          laporan_disetujui: laporan.filter(l => l.status === 'Disetujui').length,
          status_magang: 'Aktif',
          sertifikat_status: sertifikat ? sertifikat.status : 'Belum Diajukan',
          sertifikat_url: sertifikat ? sertifikat.download_url : null
        });
      });
    });
  });
});

// Admin Get All Siswa
app.get('/api/admin/siswa', authenticateToken, (req, res) => {
  db.all("SELECT id, nama, email, role, nis, sekolah, tempat_magang FROM users WHERE role = 'siswa'", (err, siswaRows) => {
    if (err) return res.status(500).json({ message: err.message });

    // Gabungkan data absensi, laporan, dan izin untuk masing-masing siswa
    let completed = 0;
    if (siswaRows.length === 0) return res.json([]);

    siswaRows.forEach(siswa => {
      db.all('SELECT * FROM absensi WHERE user_id = ?', [siswa.id], (err, absensi) => {
        db.all('SELECT * FROM laporan WHERE user_id = ?', [siswa.id], (err, laporan) => {
          db.all('SELECT * FROM izin WHERE user_id = ?', [siswa.id], (err, izin) => {
            siswa.absensi = absensi || [];
            siswa.laporan = laporan || [];
            siswa.izin = izin || [];

            completed++;
            if (completed === siswaRows.length) {
              res.json(siswaRows);
            }
          });
        });
      });
    });
  });
});

// Admin verifikasi laporan
app.post('/api/admin/laporan/verify', authenticateToken, (req, res) => {
  const { laporanId, status, catatan } = req.body;
  db.run(`
    UPDATE laporan
    SET status = ?, catatan_pembimbing = ?
    WHERE id = ?
  `, [status, catatan, laporanId], (err) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json({ success: true });
  });
});

// Admin verifikasi izin
app.post('/api/admin/izin/verify', authenticateToken, (req, res) => {
  const { izinId, status } = req.body;
  db.run(`
    UPDATE izin
    SET status = ?
    WHERE id = ?
  `, [status, izinId], (err) => {
    if (err) return res.status(500).json({ message: err.message });
    res.json({ success: true });
  });
});

// Admin verifikasi & buat sertifikat
app.post('/api/admin/sertifikat/verify', authenticateToken, (req, res) => {
  const { user_id, status, download_url } = req.body;
  const now = new Date().toISOString();

  db.get('SELECT * FROM sertifikat WHERE user_id = ?', [user_id], (err, row) => {
    if (err) return res.status(500).json({ message: err.message });

    if (row) {
      db.run(`
        UPDATE sertifikat
        SET status = ?, diproses_pada = ?, disetujui_pada = ?, download_url = ?
        WHERE user_id = ?
      `, [status, status === 'Sedang Diproses' ? now : row.diproses_pada, status === 'Tersedia' ? now : row.disetujui_pada, download_url, user_id], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json({ success: true });
      });
    } else {
      db.run(`
        INSERT INTO sertifikat (id, user_id, status, diajukan_pada, download_url)
        VALUES (?, ?, ?, ?, ?)
      `, [`sert_${Date.now()}`, user_id, status, now, download_url], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json({ success: true });
      });
    }
  });
});

// Get admin stats & badge info
app.get('/api/admin/stats', authenticateToken, (req, res) => {
  db.get("SELECT COUNT(*) as active FROM users WHERE role = 'siswa'", (err, rSiswa) => {
    db.get("SELECT COUNT(*) as pendingLaporan FROM laporan WHERE status = 'Pending'", (err, rLaporan) => {
      db.get("SELECT COUNT(*) as pendingIzin FROM izin WHERE status = 'Pending'", (err, rIzin) => {
        db.get("SELECT COUNT(*) as pendingSertifikat FROM sertifikat WHERE status IN ('Menunggu Review', 'Sedang Diproses')", (err, rSert) => {
          db.get("SELECT COUNT(*) as unreadChats FROM chats WHERE sender_role = 'siswa' AND is_read = 0", (err, rChat) => {
            const today = new Date().toISOString().split('T')[0];
            db.get("SELECT COUNT(*) as hadirToday FROM absensi WHERE tanggal = ? AND status_masuk IN ('Hadir', 'Terlambat')", [today], (err, rHadir) => {
              res.json({
                siswaAktif: rSiswa ? rSiswa.active : 0,
                laporanPending: rLaporan ? rLaporan.pendingLaporan : 0,
                izinPending: rIzin ? rIzin.pendingIzin : 0,
                sertifikatPending: rSert ? rSert.pendingSertifikat : 0,
                unreadChats: rChat ? rChat.unreadChats : 0,
                absensiHariIni: rHadir ? rHadir.hadirToday : 0
              });
            });
          });
        });
      });
    });
  });
});

// Admin input / buat akun siswa baru
app.post('/api/admin/siswa', authenticateToken, async (req, res) => {
  const { nama, email, password, nis, sekolah, tempat_magang } = req.body;

  if (!nama || !email || !password || !nis) {
    return res.status(400).json({ message: 'Nama, email, password, dan NIS wajib diisi' });
  }

  try {
    const salt = await bcrypt.genSalt(10);
    const hashedPw = await bcrypt.hash(password, salt);
    const siswaId = `siswa_${Date.now()}`;

    // 1. Masukkan akun Siswa
    db.run(`
      INSERT INTO users (id, nama, email, password, role, nis, sekolah, tempat_magang)
      VALUES (?, ?, ?, ?, 'siswa', ?, ?, ?)
    `, [siswaId, nama, email, hashedPw, nis, sekolah, tempat_magang], async (err) => {
      if (err) {
        if (err.message.includes('UNIQUE')) {
          return res.status(400).json({ message: 'Email atau NIS sudah terdaftar' });
        }
        return res.status(500).json({ message: err.message });
      }

      // 2. Buat akun Orang Tua secara otomatis agar terhubung
      const ortuId = `ortu_${Date.now()}`;
      const ortuEmail = `ortu_${nis}@emagang.id`;
      const ortuName = `Orang Tua ${nama}`;
      const hashedOrtuPw = await bcrypt.hash('password123', salt); // Default password ortu

      db.run(`
        INSERT INTO users (id, nama, email, password, role, id_anak)
        VALUES (?, ?, ?, ?, 'ortu', ?)
      `, [ortuId, ortuName, ortuEmail, hashedOrtuPw, siswaId], (err) => {
        if (err) console.error('Gagal membuat akun orang tua otomatis:', err.message);
        res.status(201).json({
          message: 'Siswa berhasil ditambahkan, akun orang tua dibuat otomatis',
          siswa: { id: siswaId, nama, email, nis, sekolah, tempat_magang },
          ortuEmail
        });
      });
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server API berjalan di http://localhost:${PORT}`);
});
