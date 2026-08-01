import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/glass_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final ProfileModel profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _headline;
  late final TextEditingController _location;
  late final TextEditingController _phone;
  late final TextEditingController _summary;
  late final TextEditingController _skills;
  late final TextEditingController _companyName;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingAvatar = false;
  late String _companyLogoUrl = widget.profile.companyLogoUrl;
  late String _avatarUrl = widget.profile.avatarUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name);
    _headline = TextEditingController(text: p.headline);
    _location = TextEditingController(text: p.location);
    _phone = TextEditingController(text: p.phone);
    _summary = TextEditingController(text: p.summary);
    _skills = TextEditingController(text: p.skills.join(', '));
    _companyName = TextEditingController(text: p.companyName);
  }

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _location.dispose();
    _phone.dispose();
    _summary.dispose();
    _skills.dispose();
    _companyName.dispose();
    super.dispose();
  }

  /// Upload foto profil perusahaan (dipakai recruiter) ke bucket
  /// 'company-logos', lalu langsung simpan URL-nya ke profil.
  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final bytes = await picked.readAsBytes();
      final uid = widget.profile.id;
      final ext = picked.path.split('.').last;
      final path = '$uid/${const Uuid().v4()}.$ext';
      final url = await SupabaseService.instance
          .uploadFile(bucket: 'company-logos', path: path, bytes: bytes);
      await SupabaseService.instance.updateProfile(uid, {'company_logo_url': url});
      ref.invalidate(currentProfileProvider);
      setState(() => _companyLogoUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto perusahaan berhasil diperbarui.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  /// Upload foto profil pencari kerja ke bucket 'avatars', lalu langsung
  /// simpan URL-nya ke kolom avatar_url di tabel profiles.
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final uid = widget.profile.id;
      final ext = picked.path.split('.').last;
      final path = '$uid/${const Uuid().v4()}.$ext';
      final url =
          await SupabaseService.instance.uploadFile(bucket: 'avatars', path: path, bytes: bytes);
      await SupabaseService.instance.updateProfile(uid, {'avatar_url': url});
      ref.invalidate(currentProfileProvider);
      setState(() => _avatarUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final skillsList = _skills.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final data = <String, dynamic>{
        'name': _name.text.trim(),
        'headline': _headline.text.trim(),
        'location': _location.text.trim(),
        'phone': _phone.text.trim(),
        'summary': _summary.text.trim(),
        'skills': skillsList,
      };
      if (widget.profile.isRecruiter) {
        data['company_name'] = _companyName.text.trim();
      }

      await SupabaseService.instance.updateProfile(widget.profile.id, data);
      ref.invalidate(currentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      );

  @override
  Widget build(BuildContext context) {
    final isRecruiter = widget.profile.isRecruiter;

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
                    const Text('Edit Profil',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    if (!isRecruiter) ...[
                      Center(
                        child: GestureDetector(
                          onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                          child: Stack(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.black,
                                  image: _avatarUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(_avatarUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _uploadingAvatar
                                    ? const Center(
                                        child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white)))
                                    : (_avatarUrl.isEmpty
                                        ? const Icon(Icons.person_rounded,
                                            color: Colors.white54, size: 32)
                                        : null),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.black,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text('Foto Profil',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (isRecruiter) ...[
                      Center(
                        child: GestureDetector(
                          onTap: _uploadingLogo ? null : _pickAndUploadLogo,
                          child: Stack(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.black,
                                  image: _companyLogoUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(_companyLogoUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _uploadingLogo
                                    ? const Center(
                                        child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white)))
                                    : (_companyLogoUrl.isEmpty
                                        ? const Icon(Icons.apartment_rounded,
                                            color: Colors.white54, size: 32)
                                        : null),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.black,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text('Foto Profil Perusahaan',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 18),
                    ],
                    GlassPane(
                      borderRadius: 22,
                      child: Column(
                        children: [
                          TextField(controller: _name, decoration: _dec('Nama Lengkap', Icons.badge_outlined)),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _headline,
                            decoration: _dec(
                                isRecruiter ? 'Jabatan' : 'Headline (mis. Frontend Developer)',
                                Icons.work_outline_rounded),
                          ),
                          const SizedBox(height: 14),
                          if (isRecruiter) ...[
                            TextField(
                                controller: _companyName,
                                decoration: _dec('Nama Perusahaan', Icons.apartment_rounded)),
                            const SizedBox(height: 14),
                          ],
                          TextField(
                              controller: _location,
                              decoration: _dec('Lokasi', Icons.location_on_outlined)),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: _dec('Nomor HP', Icons.phone_outlined),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _summary,
                            maxLines: 4,
                            decoration: _dec('Ringkasan Tentang Kamu', Icons.notes_rounded),
                          ),
                          if (!isRecruiter) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _skills,
                              decoration: _dec(
                                  'Skill (pisahkan dengan koma)', Icons.auto_awesome_rounded),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryPillButton(
                      label: 'Simpan Perubahan',
                      loading: _saving,
                      onPressed: _save,
                      icon: Icons.check_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
