import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/job_model.dart';
import 'glass_widgets.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.isSaved = false,
    this.onBookmark,
  });

  String _salaryText() {
    if (job.salaryMin != null && job.salaryMax != null) {
      final f = NumberFormat.compact(locale: 'id_ID');
      return 'Rp${f.format(job.salaryMin)} - Rp${f.format(job.salaryMax)}';
    }
    return job.salaryDisplay;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassPane(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      job.company.isNotEmpty ? job.company[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(job.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onBookmark,
                  child: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GlassChip(label: _salaryText(), icon: Icons.payments_outlined),
                GlassChip(label: job.jobType, icon: Icons.schedule_rounded),
                GlassChip(label: job.location, icon: Icons.location_on_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
