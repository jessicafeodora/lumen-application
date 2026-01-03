import 'package:flutter/material.dart';
import 'package:lumen_application/widgets/glass.dart';
import 'package:lumen_application/theme/lumen_theme.dart';
import 'package:lumen_application/services/activity_rtdb.dart';

class ActivityLogCard extends StatelessWidget {
  final List<ActivityEntry> entries;

  const ActivityLogCard({super.key, required this.entries});

  String _actorLabel(String actor) {
    return actor.toLowerCase() == 'device' ? 'Device' : 'App';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Glass(
      size: GlassSize.md,
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          entries.isEmpty
              ? Text('No activity yet', style: theme.textTheme.bodySmall?.copyWith(color: muted))
              : ListView.separated(
            shrinkWrap: true,
            itemCount: entries.length,
            separatorBuilder: (_, __) => Divider(height: 18),
            itemBuilder: (_, i) {
              final e = entries[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.action,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${e.timestampLabel} · ${_actorLabel(e.actor)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
