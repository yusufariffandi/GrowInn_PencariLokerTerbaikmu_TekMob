class JobModel {
  final String id;
  final String recruiterId;
  final String title;
  final String company;
  final String companyLogoUrl;
  final String location;
  final String city;
  final double lat;
  final double lng;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryDisplay;
  final String experienceLevel;
  final String jobType;
  final String industry;
  final String description;
  final String qualifications;
  final String aboutCompany;
  final int applicantsCount;
  final bool isActive;
  final List<String> galleryUrls;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.recruiterId,
    required this.title,
    required this.company,
    this.companyLogoUrl = '',
    required this.location,
    this.city = 'Yogyakarta',
    this.lat = -7.79,
    this.lng = 110.38,
    this.salaryMin,
    this.salaryMax,
    this.salaryDisplay = 'Negotiable',
    this.experienceLevel = 'Mid',
    this.jobType = 'Full-time',
    this.industry = '',
    this.description = '',
    this.qualifications = '',
    this.aboutCompany = '',
    this.applicantsCount = 0,
    this.isActive = true,
    this.galleryUrls = const [],
    required this.createdAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      recruiterId: json['recruiter_id'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      companyLogoUrl: json['company_logo_url'] ?? '',
      location: json['location'] ?? '',
      city: json['city'] ?? 'Yogyakarta',
      lat: (json['lat'] as num?)?.toDouble() ?? -7.79,
      lng: (json['lng'] as num?)?.toDouble() ?? 110.38,
      salaryMin: (json['salary_min'] as num?)?.toDouble(),
      salaryMax: (json['salary_max'] as num?)?.toDouble(),
      salaryDisplay: json['salary_display'] ?? 'Negotiable',
      experienceLevel: json['experience_level'] ?? 'Mid',
      jobType: json['job_type'] ?? 'Full-time',
      industry: json['industry'] ?? '',
      description: json['description'] ?? '',
      qualifications: json['qualifications'] ?? '',
      aboutCompany: json['about_company'] ?? '',
      applicantsCount: json['applicants_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      galleryUrls: (json['gallery_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'recruiter_id': recruiterId,
        'title': title,
        'company': company,
        'company_logo_url': companyLogoUrl,
        'location': location,
        'city': city,
        'lat': lat,
        'lng': lng,
        'salary_min': salaryMin,
        'salary_max': salaryMax,
        'salary_display': salaryDisplay,
        'experience_level': experienceLevel,
        'job_type': jobType,
        'industry': industry,
        'description': description,
        'qualifications': qualifications,
        'about_company': aboutCompany,
        'gallery_urls': galleryUrls,
      };
}
