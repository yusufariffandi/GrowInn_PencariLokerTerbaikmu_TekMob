import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';

/// Daftar percakapan — dibangun dari tabel `messages`, dikelompokkan per lawan bicara.
class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  bool _loading = true;
  List<ChatThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final client = SupabaseService.instance.client;
    final rows = await client
        .from('messages')
        .select()
        .or('sender_id.eq.$uid,receiver_id.eq.$uid')
        .order('created_at', ascending: false);

    final Map<String, ChatThread> grouped = {};
    for (final r in rows) {
      final isSender = r['sender_id'] == uid;
      final peerId = isSender ? r['receiver_id'] : r['sender_id'];
      if (grouped.containsKey(peerId)) continue;
      grouped[peerId] = ChatThread(
        peerId: peerId,
        peerName: peerId, // di-resolve di bawah
        lastMessage: r['text'] ?? '',
        lastTime: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
        unreadCount: (!isSender && r['read_status'] == false) ? 1 : 0,
      );
    }

    // Resolve nama lawan bicara dari tabel profiles
    final threads = <ChatThread>[];
    for (final t in grouped.values) {
      final profile = await SupabaseService.instance.getProfile(t.peerId);
      threads.add(ChatThread(
        peerId: t.peerId,
        peerName: profile?['name'] ?? 'Pengguna',
        peerAvatar: profile?['avatar_url'] ?? '',
        lastMessage: t.lastMessage,
        lastTime: t.lastTime,
        unreadCount: t.unreadCount,
      ));
    }

    setState(() {
      _threads = threads;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                    child: Text('Pesan',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _threads.isEmpty
                    ? const Center(
                        child: Text('Belum ada percakapan.',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: _threads.length,
                        itemBuilder: (c, i) {
                          final t = _threads[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => context.push('/chat/${t.peerId}', extra: {'name': t.peerName}),
                              borderRadius: BorderRadius.circular(20),
                              child: GlassPane(
                                borderRadius: 20,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: const BoxDecoration(
                                          color: AppColors.black, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          t.peerName.isNotEmpty ? t.peerName[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.peerName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(t.lastMessage,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: AppColors.textSecondary, fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                    Text(DateFormat('HH:mm').format(t.lastTime),
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
