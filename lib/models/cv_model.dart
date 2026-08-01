/// Model CV berbasis TEMPLATE (bukan generatif-AI) — struktur mengikuti
/// format CV umum: Data Pribadi, Pendidikan, Pengalaman, Keahlian, Kontak, Hobi.

class CVEducation {
  String institution;
  String year; // contoh: "2014 – 2018"
  CVEducation({this.institution = '', this.year = ''});

  Map<String, dynamic> toJson() => {'institution': institution, 'year': year};
  factory CVEducation.fromJson(Map<String, dynamic> j) =>
      CVEducation(institution: j['institution'] ?? '', year: j['year'] ?? '');
}

class CVExperience {
  String title; // contoh: "Komunikasi Internal"
  String subtitle; // contoh: "Strategi Komunikasi (Juni 2018 – Juli 2018)"
  List<String> bullets;
  CVExperience({this.title = '', this.subtitle = '', List<String>? bullets})
      : bullets = bullets ?? [''];

  Map<String, dynamic> toJson() =>
      {'title': title, 'subtitle': subtitle, 'bullets': bullets};
  factory CVExperience.fromJson(Map<String, dynamic> j) => CVExperience(
        title: j['title'] ?? '',
        subtitle: j['subtitle'] ?? '',
        bullets: ((j['bullets'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

class CVModel {
  final String id;
  final String userId;

  // Header
  String fullname;
  String tagline; // contoh: "Lulusan Baru"
  String summary;
  String photoUrl;

  // Data Pribadi
  String birthPlace;
  String birthDate;
  String address;
  String phone;
  String gender;
  String religion;
  String nationality;
  String email;
  String maritalStatus;

  // Kontak (ditampilkan terpisah di sidebar, bisa beda dari data pribadi)
  String contactPhone;
  String contactAddress;
  String contactWebsite;

  List<CVEducation> educations;
  List<CVExperience> experiences;
  List<String> skills;
  List<String> hobbies;

  bool isTemplateGenerated;

  CVModel({
    this.id = '',
    this.userId = '',
    this.fullname = '',
    this.tagline = '',
    this.summary = '',
    this.photoUrl = '',
    this.birthPlace = '',
    this.birthDate = '',
    this.address = '',
    this.phone = '',
    this.gender = '',
    this.religion = '',
    this.nationality = 'Indonesia',
    this.email = '',
    this.maritalStatus = '',
    this.contactPhone = '',
    this.contactAddress = '',
    this.contactWebsite = '',
    List<CVEducation>? educations,
    List<CVExperience>? experiences,
    List<String>? skills,
    List<String>? hobbies,
    this.isTemplateGenerated = true,
  })  : educations = educations ?? [CVEducation()],
        experiences = experiences ?? [CVExperience()],
        skills = skills ?? [''],
        hobbies = hobbies ?? [''];

  factory CVModel.fromJson(Map<String, dynamic> json) {
    return CVModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fullname: json['fullname'] ?? '',
      tagline: json['title'] ?? '',
      summary: json['summary'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      birthPlace: json['birth_place'] ?? '',
      birthDate: json['birth_date'] ?? '',
      address: json['location'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      religion: json['religion'] ?? '',
      nationality: json['nationality'] ?? 'Indonesia',
      email: json['email'] ?? '',
      maritalStatus: json['marital_status'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      contactAddress: json['contact_address'] ?? '',
      contactWebsite: json['contact_website'] ?? '',
      educations: ((json['educations'] as List?) ?? [])
          .map((e) => CVEducation.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      experiences: ((json['experiences'] as List?) ?? [])
          .map((e) => CVExperience.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      skills: ((json['skills_tech'] as List?) ?? []).map((e) => e.toString()).toList(),
      hobbies: ((json['skills_soft'] as List?) ?? []).map((e) => e.toString()).toList(),
      isTemplateGenerated: true,
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'fullname': fullname,
        'title': tagline,
        'summary': summary,
        'photo_url': photoUrl,
        'birth_place': birthPlace,
        'birth_date': birthDate,
        'location': address,
        'phone': phone,
        'gender': gender,
        'religion': religion,
        'nationality': nationality,
        'email': email,
        'marital_status': maritalStatus,
        'contact_phone': contactPhone,
        'contact_address': contactAddress,
        'contact_website': contactWebsite,
        'educations': educations.map((e) => e.toJson()).toList(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        // kolom skills_tech & skills_soft (JSONB/array di DB) dipakai ulang
        // untuk menyimpan daftar Keahlian & Hobi agar tak perlu migrasi kolom baru.
        'skills_tech': skills.where((s) => s.trim().isNotEmpty).toList(),
        'skills_soft': hobbies.where((s) => s.trim().isNotEmpty).toList(),
        'is_ai_generated': false,
      };
}
