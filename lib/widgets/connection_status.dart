import 'package:flutter/material.dart';
import 'package:lumen_application/widgets/glass.dart';

class ConnectionStatusTile extends StatelessWidget {
  final bool isConnected;
  final String deviceName;
  final String lastUpdated;

  const ConnectionStatusTile({
    super.key,
    required this.isConnected,
    required this.deviceName,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF22C55E);
    final red = const Color(0xFFF87171);

    return Glass(
      size: GlassSize.sm,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 18,
            color: isConnected ? green : red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  lastUpdated,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isConnected ? 'Online' : '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isConnected ? green : red,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionStatusBar extends StatelessWidget {
  final bool isConnected;
  final bool showOnlineRight;

  const ConnectionStatusBar({
    super.key,
    required this.isConnected,
    required this.showOnlineRight,
  });

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF22C55E);
    final red = const Color(0xFFF87171);

    return Row(
      children: [
        Icon(
          isConnected ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: isConnected ? green : red,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (showOnlineRight)
          Text(
            isConnected ? 'Online' : '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isConnected ? green : red,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}
