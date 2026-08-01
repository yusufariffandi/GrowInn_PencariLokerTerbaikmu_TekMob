import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/glass_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('$e')),
        data: (profile) {
          if (profile == null) return const SizedBox();
          final isRecruiter = profile.isRecruiter;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Center(
                child: Column(
                  children: [
                    Builder(builder: (_) {
                      final photoUrl =
                          isRecruiter ? profile.companyLogoUrl : profile.avatarUrl;
                      return Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          shape: BoxShape.circle,
                          image: photoUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: photoUrl.isEmpty
                            ? Center(
                                child: Text(
                                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'G',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800),
                                ),
                              )
                            : null,
                      );
                    }),
                    const SizedBox(height: 12),
                    Text(profile.name.isNotEmpty ? profile.name : 'Pengguna GrowIn',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    GlassChip(
                        label: isRecruiter ? 'Rekruter' : 'Karyawan',
                        icon: isRecruiter
                            ? Icons.business_center_rounded
                            : Icons.person_search_rounded),
                    if (isRecruiter && profile.companyName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(profile.companyName,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!isRecruiter) ...[
                GlassPane(
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Kelengkapan Profil',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          Text('${profile.completeness}%',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: profile.completeness / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.outlineVariant,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _MenuTile(
                icon: Icons.edit_outlined,
                label: 'Edit Profil',
                onTap: () => context.push('/profile/edit', extra: profile),
              ),
              if (!isRecruiter) ...[
                _MenuTile(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Lowongan Tersimpan',
                  onTap: () => context.push('/saved-jobs'),
                ),
                _MenuTile(
                  icon: Icons.checklist_rounded,
                  label: 'Application Tracker',
                  onTap: () => context.push('/tracker'),
                ),
                _MenuTile(
                  icon: Icons.description_outlined,
                  label: 'CV Saya',
                  onTap: () => context.push('/cv/list'),
                ),
              ] else ...[
                _MenuTile(
                  icon: Icons.add_business_rounded,
                  label: 'Pasang Lowongan Baru',
                  onTap: () => context.push('/recruiter/post-job'),
                ),
              ],
              _MenuTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifikasi',
                onTap: () => context.push('/notifications'),
              ),
              _MenuTile(
                icon: Icons.help_outline_rounded,
                label: 'Bantuan',
                onTap: () => context.push('/help'),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go('/role-select');
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                label: const Text('Keluar', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassPane(
          borderRadius: 18,
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
