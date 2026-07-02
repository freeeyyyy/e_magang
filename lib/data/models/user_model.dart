enum UserRole { siswa, ortu, admin }

class UserModel {
  final String id;
  final String nama;
  final String email;
  final UserRole role;
  final String? token;
  
  // Specific attributes for Student
  final String? nis;
  final String? sekolah;
  final String? tempatMagang;
  
  // Specific attributes for Parent
  final String? idAnak;
  final String? namaAnak;
  final String? nisAnak;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.token,
    this.nis,
    this.sekolah,
    this.tempatMagang,
    this.idAnak,
    this.namaAnak,
    this.nisAnak,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parseRole(String? r) {
      if (r == 'ortu') return UserRole.ortu;
      if (r == 'admin') return UserRole.admin;
      return UserRole.siswa;
    }
    return UserModel(
      id: json['id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: parseRole(json['role']),
      token: json['token'],
      nis: json['nis'],
      sekolah: json['sekolah'],
      tempatMagang: json['tempat_magang'],
      idAnak: json['id_anak']?.toString(),
      namaAnak: json['nama_anak'],
      nisAnak: json['nis_anak'],
    );
  }

  Map<String, dynamic> toJson() {
    String roleStr;
    if (role == UserRole.ortu) {
      roleStr = 'ortu';
    } else if (role == UserRole.admin) {
      roleStr = 'admin';
    } else {
      roleStr = 'siswa';
    }
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': roleStr,
      'token': token,
      'nis': nis,
      'sekolah': sekolah,
      'tempat_magang': tempatMagang,
      'id_anak': idAnak,
      'nama_anak': namaAnak,
      'nis_anak': nisAnak,
    };
  }

  UserModel copyWith({
    String? id,
    String? nama,
    String? email,
    UserRole? role,
    String? token,
    String? nis,
    String? sekolah,
    String? tempatMagang,
    String? idAnak,
    String? namaAnak,
    String? nisAnak,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      nis: nis ?? this.nis,
      sekolah: sekolah ?? this.sekolah,
      tempatMagang: tempatMagang ?? this.tempatMagang,
      idAnak: idAnak ?? this.idAnak,
      namaAnak: namaAnak ?? this.namaAnak,
      nisAnak: nisAnak ?? this.nisAnak,
    );
  }
}
