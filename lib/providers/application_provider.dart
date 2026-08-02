import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/application_model.dart';

final myApplicationsProvider =
    FutureProvider.family<List<ApplicationModel>, String>((ref, userId) async {
  final data = await SupabaseService.instance.getMyApplications(userId);
  return data.map((e) => ApplicationModel.fromJson(e)).toList();
});

final jobApplicationsProvider =
    FutureProvider.family<List<ApplicationModel>, String>((ref, jobId) async {
  final data = await SupabaseService.instance.getApplicationsForJob(jobId);
  return data.map((e) => ApplicationModel.fromJson(e)).toList();
});
