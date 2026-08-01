import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/auth/jobseeker_login_screen.dart';
import '../../features/auth/jobseeker_signup_screen.dart';
import '../../features/auth/recruiter_login_screen.dart';
import '../../features/auth/recruiter_signup_screen.dart';
import '../../features/home/main_shell.dart';
import '../../features/job/job_detail_screen.dart';
import '../../features/job/job_map_screen.dart';
import '../../features/job/apply_flow_screen.dart';
import '../../features/cv/cv_builder_screen.dart';
import '../../features/cv/cv_list_screen.dart';
import '../../features/cover_letter/cover_letter_builder_screen.dart';
import '../../features/cover_letter/cover_letter_list_screen.dart';
import '../../features/profile/saved_jobs_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/help_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/tracker/application_tracker_screen.dart';
import '../../features/messages/chat_screen.dart';
import '../../features/recruiter/post_job_screen.dart';
import '../../features/recruiter/candidates_screen.dart';
import '../../features/recruiter/location_picker_screen.dart';
import '../../features/ai/interview_simulator_screen.dart';
import '../../features/admin/admin_login_screen.dart';
import '../../features/admin/admin_home_screen.dart';
import '../../models/profile_model.dart';
import '../../models/job_model.dart';

/// Routing global GrowIn.
/// Alur login/signup dipisah total antara Karyawan (jobseeker) & Rekruter,
/// masing-masing punya path & screen sendiri sejak awal (bukan satu form
/// dengan dropdown role seperti prototype HTML sebelumnya).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/role-select', builder: (c, s) => const RoleSelectScreen()),

      // ---- Karyawan / Job Seeker ----
      GoRoute(path: '/login/jobseeker', builder: (c, s) => const JobseekerLoginScreen()),
      GoRoute(path: '/signup/jobseeker', builder: (c, s) => const JobseekerSignupScreen()),

      // ---- Rekruter ----
      GoRoute(path: '/login/recruiter', builder: (c, s) => const RecruiterLoginScreen()),
      GoRoute(path: '/signup/recruiter', builder: (c, s) => const RecruiterSignupScreen()),

      // ---- Admin (tersembunyi, tidak ditautkan dari role-select publik) ----
      GoRoute(path: '/login/admin', builder: (c, s) => const AdminLoginScreen()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminHomeScreen()),

      // ---- Main app (shell dengan bottom nav, konten beda per role) ----
      GoRoute(path: '/home', builder: (c, s) => const MainShell()),

      // ---- Job ----
      GoRoute(
        path: '/job/:id',
        builder: (c, s) => JobDetailScreen(jobId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/job-map', builder: (c, s) => const JobMapScreen()),
      GoRoute(
        path: '/apply/:id',
        builder: (c, s) => ApplyFlowScreen(jobId: s.pathParameters['id']!),
      ),

      // ---- CV Builder (template, bukan AI generatif) ----
      GoRoute(path: '/cv/list', builder: (c, s) => const CvListScreen()),
      GoRoute(
        path: '/cv/builder',
        builder: (c, s) => CvBuilderScreen(existing: s.extra as Map<String, dynamic>?),
      ),

      // ---- Surat Lamaran (template, bukan AI generatif) ----
      GoRoute(path: '/cover-letter/list', builder: (c, s) => const CoverLetterListScreen()),
      GoRoute(
        path: '/cover-letter/builder',
        builder: (c, s) => CoverLetterBuilderScreen(existing: s.extra as Map<String, dynamic>?),
      ),

      // ---- Profile ----
      GoRoute(path: '/saved-jobs', builder: (c, s) => const SavedJobsScreen()),
      GoRoute(path: '/tracker', builder: (c, s) => const ApplicationTrackerScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (c, s) => EditProfileScreen(profile: s.extra as ProfileModel),
      ),
      GoRoute(path: '/help', builder: (c, s) => const HelpScreen()),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),

      // ---- Messages ----
      GoRoute(
        path: '/chat/:peerId',
        builder: (c, s) => ChatScreen(
          peerId: s.pathParameters['peerId']!,
          peerName: (s.extra as Map?)?['name'] ?? 'Chat',
        ),
      ),

      // ---- Recruiter ----
      GoRoute(
        path: '/recruiter/post-job',
        builder: (c, s) => PostJobScreen(existingJob: s.extra as JobModel?),
      ),
      GoRoute(
        path: '/recruiter/candidates/:jobId',
        builder: (c, s) => CandidatesScreen(jobId: s.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/recruiter/pick-location',
        builder: (c, s) {
          final extra = s.extra as Map?;
          return LocationPickerScreen(
            initialLat: (extra?['lat'] as num?)?.toDouble() ?? -7.7956,
            initialLng: (extra?['lng'] as num?)?.toDouble() ?? 110.3695,
          );
        },
      ),

      // ---- AI Tools ----
      GoRoute(
        path: '/ai/interview-simulator',
        builder: (c, s) => InterviewSimulatorScreen(jobTitle: s.extra as String?),
      ),
    ],
  );
});
