import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/message_model.dart';

final chatMessagesProvider =
    StreamProvider.family<List<MessageModel>, ({String userId, String peerId})>((ref, args) {
  return SupabaseService.instance
      .messagesStream(args.userId, args.peerId)
      .map((rows) => rows.map((e) => MessageModel.fromJson(e)).toList());
});
