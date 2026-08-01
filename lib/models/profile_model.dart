class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'jobseeker' | 'recruiter'
  final String avatarUrl;
  final String headline;
  final String location;
  final String phone;
  final String summary;
  final List<String> skills;
  final String companyName;
  final String companyLogoUrl;
  final bool isVerified;
  final int completeness;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl = '',
    this.headline = '',
    this.location = '',
    this.phone = '',
    this.summary = '',
    this.skills = const [],
    this.companyName = '',
    this.companyLogoUrl = '',
    this.isVerified = false,
    this.completeness = 20,
  });

  bool get isRecruiter => role == 'recruiter';
  bool get isJobseeker => role == 'jobseeker';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'jobseeker',
      avatarUrl: json['avatar_url'] ?? '',
      headline: json['headline'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      summary: json['summary'] ?? '',
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      companyName: json['company_name'] ?? '',
      companyLogoUrl: json['company_logo_url'] ?? '',
      isVerified: json['is_verified'] ?? false,
      completeness: json['completeness'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar_url': avatarUrl,
        'headline': headline,
        'location': location,
        'phone': phone,
        'summary': summary,
        'skills': skills,
        'company_name': companyName,
        'company_logo_url': companyLogoUrl,
        'is_verified': isVerified,
        'completeness': completeness,
      };

  ProfileModel copyWith({
    String? name,
    String? avatarUrl,
    String? headline,
    String? location,
    String? phone,
    String? summary,
    List<String>? skills,
    String? companyName,
    String? companyLogoUrl,
    int? completeness,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      isVerified: isVerified,
      completeness: completeness ?? this.completeness,
    );
  }
}
