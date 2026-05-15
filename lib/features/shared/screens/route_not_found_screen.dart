import 'package:flutter/material.dart';
import '../../../core/routes/route_names.dart';

class RouteNotFoundScreen extends StatelessWidget {
  final String? attemptedRoute;

  const RouteNotFoundScreen({
    super.key,
    this.attemptedRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Page Not Found',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'The page you\'re looking for doesn\'t exist or is no longer available.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (attemptedRoute != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Route: $attemptedRoute',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            RouteNames.login,
                            (_) => false,
                          );
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Go to Login'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          try {
                            Navigator.pop(context);
                          } catch (_) {
                            // If pop fails, go to login
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              RouteNames.login,
                              (_) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
