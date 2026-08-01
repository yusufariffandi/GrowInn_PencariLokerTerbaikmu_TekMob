/// Model Surat Lamaran Kerja berbasis TEMPLATE — mengikuti format surat
/// lamaran formal Indonesia: tempat & tanggal, tujuan surat, sumber info
/// lowongan, data pribadi, dan daftar lampiran berkas.

class CoverLetterAttachment {
  String name;
  bool included;
  CoverLetterAttachment({required this.name, this.included = true});

  Map<String, dynamic> toJson() => {'name': name, 'included': included};
  factory CoverLetterAttachment.fromJson(Map<String, dynamic> j) =>
      CoverLetterAttachment(name: j['name'] ?? '', included: j['included'] ?? true);

  static List<CoverLetterAttachment> defaultList() => [
        CoverLetterAttachment(name: 'Curriculum Vitae (CV)'),
        CoverLetterAttachment(name: 'Fotokopi Ijazah Terakhir'),
        CoverLetterAttachment(name: 'Fotokopi Transkrip Nilai'),
        CoverLetterAttachment(name: 'Fotokopi Kartu Identitas (KTP)'),
        CoverLetterAttachment(name: 'Fotokopi Surat Keterangan Catatan Kepolisian (SKCK)'),
        CoverLetterAttachment(name: 'Fotokopi Surat Keterangan Berbadan Sehat dari Dokter'),
        CoverLetterAttachment(name: 'Fotokopi Sertifikat'),
        CoverLetterAttachment(name: 'Pasfoto Terbaru ukuran 3x4 (3 Lembar)'),
      ];
}

class CoverLetterModel {
  final String id;
  final String userId;

  // Header
  String place; // contoh: "Lombok Barat"
  String letterDate; // contoh: "30 Juni 2021"

  // Tujuan surat
  String companyName;
  String recipientTitle; // contoh: "HRD Turen Indah Group"
  String companyAddress;

  // Info lowongan (untuk paragraf pembuka)
  String sourceSite; // contoh: "https://glints.com/id"
  String sourceDate; // contoh: "29 Juni 2021"
  String position;

  // Data pribadi pelamar
  String fullname;
  String birthPlace;
  String birthDate;
  String gender;
  String address;
  String lastEducation;
  String phone;
  String email;

  List<CoverLetterAttachment> attachments;
  String signatureName;

  CoverLetterModel({
    this.id = '',
    this.userId = '',
    String? place,
    String? letterDate,
    this.companyName = '',
    this.recipientTitle = '',
    this.companyAddress = '',
    this.sourceSite = '',
    this.sourceDate = '',
    this.position = '',
    this.fullname = '',
    this.birthPlace = '',
    this.birthDate = '',
    this.gender = '',
    this.address = '',
    this.lastEducation = '',
    this.phone = '',
    this.email = '',
    List<CoverLetterAttachment>? attachments,
    this.signatureName = '',
  })  : place = place ?? '',
        letterDate = letterDate ?? _todayIndonesian(),
        attachments = attachments ?? CoverLetterAttachment.defaultList();

  static String _todayIndonesian() {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final now = DateTime.now();
    return '${now.day} ${bulan[now.month - 1]} ${now.year}';
  }

  factory CoverLetterModel.fromJson(Map<String, dynamic> json) {
    final parsedAttachments = ((json['attachments'] as List?) ?? [])
        .map((e) => CoverLetterAttachment.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return CoverLetterModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      place: json['place'] ?? '',
      letterDate: json['letter_date'] ?? _todayIndonesian(),
      companyName: json['company_name'] ?? '',
      recipientTitle: json['recipient_title'] ?? '',
      companyAddress: json['company_address'] ?? '',
      sourceSite: json['source_site'] ?? '',
      sourceDate: json['source_date'] ?? '',
      position: json['position'] ?? '',
      fullname: json['fullname'] ?? '',
      birthPlace: json['birth_place'] ?? '',
      birthDate: json['birth_date'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      lastEducation: json['last_education'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      attachments: parsedAttachments.isEmpty ? CoverLetterAttachment.defaultList() : parsedAttachments,
      signatureName: json['signature_name'] ?? (json['fullname'] ?? ''),
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'place': place,
        'letter_date': letterDate,
        'company_name': companyName,
        'recipient_title': recipientTitle,
        'company_address': companyAddress,
        'source_site': sourceSite,
        'source_date': sourceDate,
        'position': position,
        'fullname': fullname,
        'birth_place': birthPlace,
        'birth_date': birthDate,
        'gender': gender,
        'address': address,
        'last_education': lastEducation,
        'phone': phone,
        'email': email,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'signature_name': signatureName.isNotEmpty ? signatureName : fullname,
      };
}
