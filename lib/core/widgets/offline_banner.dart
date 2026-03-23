import 'package:flutter/material.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  static void simulateOffline() => isOnline.value = false;
  static void simulateOnline() => isOnline.value = true;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _online = OfflineBanner.isOnline.value;

  @override
  void initState() {
    super.initState();
    OfflineBanner.isOnline.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    OfflineBanner.isOnline.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    setState(() => _online = OfflineBanner.isOnline.value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _online ? 0 : 48,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
          ),
          child: Material(
            color: Colors.orange.shade700,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "You're offline - showing cached data",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
