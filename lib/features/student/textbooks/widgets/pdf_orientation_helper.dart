import 'package:flutter/material.dart';

/// Model to track orientation state and preferences
class OrientationState {
  /// Current device orientation
  final Orientation currentOrientation;
  
  /// User's orientation preference (null = auto, portrait, landscape)
  final Orientation? userPreference;
  
  /// Current zoom level (1.0 = 100%)
  final double zoomLevel;
  
  /// Scroll position
  final Offset scrollPosition;

  const OrientationState({
    required this.currentOrientation,
    this.userPreference,
    this.zoomLevel = 1.0,
    this.scrollPosition = Offset.zero,
  });

  /// Whether to use auto orientation (follow device)
  bool get isAutoOrientation => userPreference == null;

  /// Get the effective orientation to use
  Orientation getEffectiveOrientation() {
    return userPreference ?? currentOrientation;
  }

  OrientationState copyWith({
    Orientation? currentOrientation,
    Orientation? userPreference,
    double? zoomLevel,
    Offset? scrollPosition,
  }) {
    return OrientationState(
      currentOrientation: currentOrientation ?? this.currentOrientation,
      userPreference: userPreference ?? this.userPreference,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      scrollPosition: scrollPosition ?? this.scrollPosition,
    );
  }
}

/// Widget to manage PDF viewer orientation and fit
class OrientationManager {
  /// Determine the best fit method for a PDF page based on orientation
  static BoxFit getFitMethod(
    Orientation orientation, {
    required double pageWidth,
    required double pageHeight,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final pageAspectRatio = pageWidth / pageHeight;
    final viewportAspectRatio = viewportWidth / viewportHeight;

    // If aspect ratios are similar, use cover (fill entire viewport)
    if ((pageAspectRatio - viewportAspectRatio).abs() < 0.1) {
      return BoxFit.cover;
    }

    // For portrait mode or tall pages, use fitHeight to fit within height
    if (orientation == Orientation.portrait || pageAspectRatio < 0.7) {
      return BoxFit.fitHeight;
    }

    // For landscape mode or wide pages, use fitWidth
    return BoxFit.fitWidth;
  }

  /// Calculate the optimal zoom level to fit page in viewport
  static double calculateFitZoom({
    required double pageWidth,
    required double pageHeight,
    required double viewportWidth,
    required double viewportHeight,
    BoxFit fit = BoxFit.fitWidth,
  }) {
    switch (fit) {
      case BoxFit.fitWidth:
        return viewportWidth / pageWidth;
      case BoxFit.fitHeight:
        return viewportHeight / pageHeight;
      case BoxFit.cover:
        return (viewportWidth / pageWidth).clamp(
          viewportHeight / pageHeight,
          double.infinity,
        );
      case BoxFit.contain:
        return ([viewportWidth / pageWidth, viewportHeight / pageHeight]
            .reduce((a, b) => a < b ? a : b));
      default:
        return 1.0;
    }
  }

  /// Check if a page is in portrait or landscape orientation
  static Orientation detectPageOrientation({
    required double width,
    required double height,
  }) {
    return width > height ? Orientation.landscape : Orientation.portrait;
  }
}

/// Enhanced PDF viewer with better orientation and fit handling
class PdfOrientationHelper extends StatefulWidget {
  final Widget pdfViewer;
  final double pageWidth;
  final double pageHeight;
  final ValueChanged<OrientationState>? onOrientationStateChanged;

  const PdfOrientationHelper({
    super.key,
    required this.pdfViewer,
    required this.pageWidth,
    required this.pageHeight,
    this.onOrientationStateChanged,
  });

  @override
  State<PdfOrientationHelper> createState() => _PdfOrientationHelperState();
}

class _PdfOrientationHelperState extends State<PdfOrientationHelper> {
  late OrientationState _orientationState;

  @override
  void initState() {
    super.initState();
    _orientationState = OrientationState(
      currentOrientation: MediaQuery.of(context).orientation,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newOrientation = MediaQuery.of(context).orientation;
    if (_orientationState.currentOrientation != newOrientation) {
      _updateOrientation(newOrientation);
    }
  }

  void _updateOrientation(Orientation newOrientation) {
    setState(() {
      _orientationState = _orientationState.copyWith(
        currentOrientation: newOrientation,
      );
    });
    widget.onOrientationStateChanged?.call(_orientationState);
  }

  void _setOrientationPreference(Orientation? preference) {
    setState(() {
      _orientationState = _orientationState.copyWith(
        userPreference: preference,
      );
    });
    widget.onOrientationStateChanged?.call(_orientationState);
  }

  void _updateZoom(double zoom) {
    setState(() {
      _orientationState = _orientationState.copyWith(zoomLevel: zoom);
    });
    widget.onOrientationStateChanged?.call(_orientationState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PDF Viewer
          widget.pdfViewer,

          // Orientation and fit controls
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'auto_orientation',
                  onPressed: () => _setOrientationPreference(null),
                  child: Icon(
                    _orientationState.isAutoOrientation
                        ? Icons.screen_rotation
                        : Icons.screen_lock_rotation,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'portrait_lock',
                  onPressed: () => _setOrientationPreference(Orientation.portrait),
                  child: Icon(
                    _orientationState.userPreference == Orientation.portrait
                        ? Icons.stay_primary_portrait
                        : Icons.stay_current_portrait,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'landscape_lock',
                  onPressed: () => _setOrientationPreference(Orientation.landscape),
                  child: Icon(
                    _orientationState.userPreference == Orientation.landscape
                        ? Icons.stay_primary_landscape
                        : Icons.stay_current_landscape,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _updateZoom((_orientationState.zoomLevel + 0.1).clamp(0.5, 3.0));
                  },
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_actual',
                  onPressed: () {
                    _updateZoom(1.0);
                  },
                  child: const Icon(Icons.zoom_out_map),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
