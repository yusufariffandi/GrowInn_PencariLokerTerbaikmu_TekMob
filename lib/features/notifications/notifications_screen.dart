import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String category) {
    switch (category) {
      case 'status':
        return Icons.fact_check_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'tips':
        return Icons.lightbulb_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = SupabaseService.instance.currentUserId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    const Text('Notifikasi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: uid == null
                    ? const Center(
                        child: Text('Silakan masuk untuk melihat notifikasi.',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : Consumer(
                        builder: (context, ref, _) {
                          final notifAsync = ref.watch(notificationsProvider(uid));
                          return notifAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, st) => Center(
                              child: Text('Gagal memuat notifikasi: $e',
                                  style: const TextStyle(color: AppColors.textSecondary)),
                            ),
                            data: (items) {
                              if (items.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      'Belum ada notifikasi. Update lowongan, status lamaran, '
                                      'dan pesan baru akan muncul di sini.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                                itemCount: items.length,
                                itemBuilder: (context, i) {
                                  final NotificationModel n = items[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () async {
                                        if (!n.isRead) {
                                          await SupabaseService.instance
                                              .markNotificationRead(n.id);
                                        }
                                        if (n.actionUrl.isNotEmpty && context.mounted) {
                                          context.push(n.actionUrl);
                                        }
                                      },
                                      child: GlassPane(
                                        borderRadius: 18,
                                        tint: n.isRead
                                            ? null
                                            : Colors.white.withValues(alpha: 0.55),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(colors: [
                                                  AppColors.primary,
                                                  AppColors.primaryContainer,
                                                ]),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Icon(_iconFor(n.category),
                                                  color: Colors.white, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(n.title,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13.5)),
                                                  if (n.body.isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Text(n.body,
                                                        style: const TextStyle(
                                                            color: AppColors.textSecondary,
                                                            fontSize: 12)),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (!n.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(top: 4, left: 6),
                                                decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
