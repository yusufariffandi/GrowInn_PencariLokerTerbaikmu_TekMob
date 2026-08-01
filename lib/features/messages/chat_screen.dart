import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/message_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';

const _kImageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

class ChatScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String peerName;
  const ChatScreen({super.key, required this.peerId, required this.peerName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _attaching = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;
    _controller.clear();
    await SupabaseService.instance.sendMessage(
      senderId: uid,
      receiverId: widget.peerId,
      text: text,
    );
  }

  /// Membuka file picker device (galeri foto, dokumen, dsb), lalu upload
  /// ke bucket 'chat-attachments' dan kirim sebagai pesan dengan lampiran.
  Future<void> _pickAndSendAttachment() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final fileName = result.files.single.name;
    final bytes = result.files.single.bytes!;

    setState(() => _attaching = true);
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
      final storagePath = '$uid/${const Uuid().v4()}.$ext';
      final url = await SupabaseService.instance
          .uploadFile(bucket: 'chat-attachments', path: storagePath, bytes: bytes);

      await SupabaseService.instance.sendMessage(
        senderId: uid,
        receiverId: widget.peerId,
        text: _kImageExts.contains(ext.toLowerCase()) ? '📷 Foto' : '📎 $fileName',
        attachmentUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengirim file: $e')));
      }
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return _kImageExts.any((e) => lower.endsWith('.$e'));
  }

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseService.instance.currentUserId ?? '';
    final messagesAsync = ref.watch(chatMessagesProvider((userId: uid, peerId: widget.peerId)));

    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          shape: const CircleBorder()),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.peerName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('$e')),
                  data: (messages) {
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      itemCount: messages.length,
                      itemBuilder: (c, i) {
                        final m = messages[messages.length - 1 - i];
                        final isMe = m.senderId == uid;
                        final hasAttachment = m.attachmentUrl.isNotEmpty;
                        final isImage = hasAttachment && _isImageUrl(m.attachmentUrl);
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.72),
                            padding: EdgeInsets.symmetric(
                                horizontal: isImage ? 6 : 14, vertical: isImage ? 6 : 10),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.black : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isImage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: GestureDetector(
                                      onTap: () => launchUrl(Uri.parse(m.attachmentUrl),
                                          mode: LaunchMode.externalApplication),
                                      child: Image.network(
                                        m.attachmentUrl,
                                        width: 200,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, st) => Container(
                                          width: 200,
                                          height: 160,
                                          color: Colors.black12,
                                          child: const Icon(Icons.broken_image_outlined),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (hasAttachment)
                                  GestureDetector(
                                    onTap: () => launchUrl(Uri.parse(m.attachmentUrl),
                                        mode: LaunchMode.externalApplication),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: (isMe ? Colors.white : AppColors.black)
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.insert_drive_file_rounded,
                                              size: 16,
                                              color: isMe ? Colors.white : AppColors.textPrimary),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Buka lampiran',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  decoration: TextDecoration.underline,
                                                  color: isMe
                                                      ? Colors.white
                                                      : AppColors.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (m.text.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isImage ? 8 : 0, vertical: isImage ? 2 : 0),
                                    child: Text(m.text,
                                        style: TextStyle(
                                            color: isMe ? Colors.white : AppColors.textPrimary,
                                            fontSize: 13.5)),
                                  ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isImage ? 8 : 0,
                                      vertical: isImage ? 4 : 0),
                                  child: Text(DateFormat('HH:mm').format(m.createdAt),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white.withValues(alpha: 0.6)
                                              : AppColors.textSecondary)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassPane(
                  borderRadius: 9999,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _attaching ? null : _pickAndSendAttachment,
                        icon: _attaching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.attach_file_rounded),
                        color: AppColors.textSecondary,
                        tooltip: 'Kirim file dari perangkat',
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Tulis pesan...',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                            backgroundColor: AppColors.black, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
