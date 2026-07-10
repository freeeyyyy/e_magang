const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const bcrypt = require('bcryptjs');

const dbPath = path.resolve(__dirname, 'database.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Koneksi database gagal:', err.message);
  } else {
    console.log('Terhubung ke database SQLite lokal.');
  }
});

// Setup tabel database
db.serialize(() => {
  // 1. Users
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      nama TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL, -- 'siswa', 'ortu', 'admin'
      nis TEXT UNIQUE,
      sekolah TEXT,
      tempat_magang TEXT,
      id_anak TEXT
    )
  `);

  // 2. Absensi
  db.run(`
    CREATE TABLE IF NOT EXISTS absensi (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      tanggal TEXT NOT NULL, -- YYYY-MM-DD
      waktu_masuk TEXT,
      waktu_keluar TEXT,
      status_masuk TEXT, -- 'Hadir', 'Terlambat', 'Alpa', 'Izin'
      status_keluar TEXT, -- 'Hadir', 'Tepat Waktu'
      lokasi_masuk TEXT,
      lokasi_keluar TEXT,
      is_valid INTEGER DEFAULT 1,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  `);

  // 3. Laporan
  db.run(`
    CREATE TABLE IF NOT EXISTS laporan (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      tanggal TEXT NOT NULL, -- YYYY-MM-DD
      kegiatan TEXT NOT NULL,
      status TEXT DEFAULT 'Pending', -- 'Pending', 'Disetujui', 'Ditolak'
      dokumentasi_url TEXT,
      catatan_pembimbing TEXT,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  `);

  // 4. Izin
  db.run(`
    CREATE TABLE IF NOT EXISTS izin (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      tanggal_mulai TEXT NOT NULL,
      tanggal_selesai TEXT NOT NULL,
      tipe TEXT NOT NULL, -- 'Sakit', 'Izin'
      keterangan TEXT NOT NULL,
      lampiran_url TEXT,
      status TEXT DEFAULT 'Pending', -- 'Pending', 'Disetujui', 'Ditolak'
      catatan TEXT,
      diajukan_pada TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  `);

  // 5. Sertifikat
  db.run(`
    CREATE TABLE IF NOT EXISTS sertifikat (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      status TEXT NOT NULL, -- 'Menunggu Review', 'Sedang Diproses', 'Tersedia', 'Ditolak'
      diajukan_pada TEXT NOT NULL,
      diproses_pada TEXT,
      disetujui_pada TEXT,
      download_url TEXT,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
  `);

  // 6. Chats
  db.run(`
    CREATE TABLE IF NOT EXISTS chats (
      id TEXT PRIMARY KEY,
      siswa_id TEXT NOT NULL,
      sender_id TEXT NOT NULL,
      sender_role TEXT NOT NULL, -- 'siswa', 'admin'
      message TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      is_read INTEGER DEFAULT 0
    )
  `);

  // Seed user bawaan jika kosong
  db.get("SELECT COUNT(*) as count FROM users", async (err, row) => {
    if (row && row.count === 0) {
      const salt = await bcrypt.genSalt(10);
      const hashedPw = await bcrypt.hash('password123', salt);

      // 1. Admin
      db.run(`
        INSERT INTO users (id, nama, email, password, role)
        VALUES ('admin_001', 'Administrator', 'admin@emagang.id', ?, 'admin')
      `, [hashedPw]);

      // 2. Siswa (Robert James)
      db.run(`
        INSERT INTO users (id, nama, email, password, role, nis, sekolah, tempat_magang)
        VALUES ('siswa_001', 'Robert James', 'siswa@emagang.id', ?, 'siswa', '20240901', 'SMK Negeri 1 Bengkalis', 'PT. Media Balai Nusa Astronet Bengkalis')
      `, [hashedPw]);

      // 3. Orang Tua
      db.run(`
        INSERT INTO users (id, nama, email, password, role, id_anak)
        VALUES ('ortu_001', 'James Senior', 'ortu@emagang.id', ?, 'ortu', 'siswa_001')
      `, [hashedPw]);

      // Seed data absensi mock untuk Robert James agar grafik / rekap terisi
      const now = new Date();
      const insertAbsensi = db.prepare(`
        INSERT INTO absensi (id, user_id, tanggal, waktu_masuk, waktu_keluar, status_masuk, status_keluar, lokasi_masuk, lokasi_keluar, is_valid)
        VALUES (?, 'siswa_001', ?, ?, ?, ?, ?, ?, ?, 1)
      `);

      for (let i = 20; i >= 1; i--) {
        const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
        if (d.getDay() === 0 || d.getDay() === 6) continue; // Skip weekend
        const dateStr = d.toISOString().split('T')[0];
        const inTime = `${dateStr}T08:00:00.000Z`;
        const outTime = `${dateStr}T17:00:00.000Z`;
        insertAbsensi.run(`abs_${i}`, dateStr, inTime, outTime, 'Hadir', 'Hadir', 'PT. Media Balai Nusa Astronet Bengkalis', 'PT. Media Balai Nusa Astronet Bengkalis');
      }
      insertAbsensi.finalize();

      console.log('Seeder user awal berhasil dimasukkan.');
    }
  });
});

module.exports = db;
