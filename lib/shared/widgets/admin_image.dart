import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_images_provider.dart';

/// Menampilkan gambar yang diatur lewat akun Admin (tabel `app_images`).
/// Selama admin belum upload apa pun untuk [imageKey], tampilkan
/// placeholder abu-abu berisi [fallbackIcon] supaya layout tidak rusak.
class AdminManagedImage extends ConsumerWidget {
  final String imageKey;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const AdminManagedImage({
    super.key,
    required this.imageKey,
    this.fallbackIcon = Icons.image_outlined,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(appImagesProvider);
    final url = imagesAsync.maybeWhen(data: (m) => m[imageKey], orElse: () => null);

    Widget content;
    if (url != null && url.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (c, _) => _placeholder(),
        errorWidget: (c, _, __) => _placeholder(),
      );
    } else {
      content = _placeholder();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(0),
      child: content,
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.lightGrey,
      child: Icon(fallbackIcon, size: 40, color: AppColors.midGrey),
    );
  }
}
