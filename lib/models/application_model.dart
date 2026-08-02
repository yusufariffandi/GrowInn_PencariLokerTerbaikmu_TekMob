class ApplicationModel {
  final String id;
  final String jobId;
  final String userId;
  final String? cvId;
  final String status; // Terkirim, Dilihat, Interview, Diterima, Ditolak
  final String coverLetter;
  final String expectedSalary;
  final String noticePeriod;
  final DateTime appliedAt;
  // joined data (opsional, diisi saat query dengan join)
  final Map<String, dynamic>? job;
  final Map<String, dynamic>? applicant;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.userId,
    this.cvId,
    this.status = 'Terkirim',
    this.coverLetter = '',
    this.expectedSalary = '',
    this.noticePeriod = 'Segera',
    required this.appliedAt,
    this.job,
    this.applicant,
  });

  static const List<String> pipeline = ['Terkirim', 'Dilihat', 'Interview', 'Diterima', 'Ditolak'];

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as String,
      jobId: json['job_id'] ?? '',
      userId: json['user_id'] ?? '',
      cvId: json['cv_id'],
      status: json['status'] ?? 'Terkirim',
      coverLetter: json['cover_letter'] ?? '',
      expectedSalary: json['expected_salary'] ?? '',
      noticePeriod: json['notice_period'] ?? 'Segera',
      appliedAt: DateTime.tryParse(json['applied_at']?.toString() ?? '') ?? DateTime.now(),
      job: json['jobs'] as Map<String, dynamic>?,
      applicant: json['profiles'] as Map<String, dynamic>?,
    );
  }
}
