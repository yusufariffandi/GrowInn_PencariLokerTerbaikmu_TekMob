import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/job_model.dart';

final jobSearchQueryProvider = StateProvider<String>((ref) => '');
final jobCityFilterProvider = StateProvider<String?>((ref) => null);

final jobListProvider = FutureProvider<List<JobModel>>((ref) async {
  final query = ref.watch(jobSearchQueryProvider);
  final city = ref.watch(jobCityFilterProvider);
  final data = await SupabaseService.instance.getJobs(city: city, query: query);
  return data.map((e) => JobModel.fromJson(e)).toList();
});

final recruiterJobsProvider =
    FutureProvider.family<List<JobModel>, String>((ref, recruiterId) async {
  final data = await SupabaseService.instance.getJobsByRecruiter(recruiterId);
  return data.map((e) => JobModel.fromJson(e)).toList();
});

final savedJobIdsProvider = StateProvider<Set<String>>((ref) => {});
