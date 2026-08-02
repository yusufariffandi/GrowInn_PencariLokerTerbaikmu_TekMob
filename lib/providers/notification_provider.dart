import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/notification_model.dart';

final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return SupabaseService.instance
      .notificationsStream(userId)
      .map((rows) => rows.map((e) => NotificationModel.fromJson(e)).toList());
});

final unreadNotificationCountProvider = Provider.family<int, String>((ref, userId) {
  final async = ref.watch(notificationsProvider(userId));
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
