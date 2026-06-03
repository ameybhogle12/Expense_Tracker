import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tour_provider.dart';

class SpotlightTourOverlay extends StatefulWidget {
  const SpotlightTourOverlay({super.key});

  @override
  State<SpotlightTourOverlay> createState() => _SpotlightTourOverlayState();
}

class _SpotlightTourOverlayState extends State<SpotlightTourOverlay> {
  @override
  Widget build(BuildContext context) {
    TourProvider tourProvider;
    try {
      tourProvider = context.watch<TourProvider>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    
    if (!tourProvider.isTourActive) return const SizedBox.shrink();

    final currentStepIdx = tourProvider.currentStep;
    final step = tourProvider.steps[currentStepIdx];
    final key = tourProvider.getKeyForStep(currentStepIdx);

    if (key == null || key.currentContext == null) {
      // Key not mounted yet, schedule a frame rebuild or skip
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
      return const SizedBox.shrink();
    }

    // Centered scrolling to make sure the target element is fully visible in scrollable lists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        try {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.35, // Align slightly above center to leave room for the tooltip card
          );
        } catch (_) {}
      }
    });

    final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final screenSize = MediaQuery.of(context).size;
    final isTopHalf = offset.dy < screenSize.height / 2;
    final double spacing = 16;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent background with Spotlight hole cutout
          GestureDetector(
            onTap: () {}, // Prevent taps reaching underlying widgets
            child: CustomPaint(
              size: screenSize,
              painter: SpotlightPainter(
                rect: Rect.fromLTWH(
                  offset.dx - 8,
                  offset.dy - 8,
                  size.width + 16,
                  size.height + 16,
                ),
              ),
            ),
          ),
          
          // Tooltip description Card - dynamically positioned based on spotlight location
          Positioned(
            top: isTopHalf ? (offset.dy + size.height + spacing).clamp(20.0, screenSize.height - 220.0) : null,
            bottom: !isTopHalf ? (screenSize.height - offset.dy + spacing).clamp(20.0, screenSize.height - 220.0) : null,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Step ${currentStepIdx + 1} of ${tourProvider.steps.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => tourProvider.skipTour(),
                          child: const Text('Skip Tour', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => tourProvider.nextStep(),
                          child: Text(
                            currentStepIdx == tourProvider.steps.length - 1 ? 'Finish' : 'Next',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Rect rect;

  SpotlightPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.70);
    
    // Draw outer rect with spotlight hole cut out using PathFillType.evenOdd
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, backgroundPaint);

    // Draw glowing primary border around spotlight hole
    final borderPaint = Paint()
      ..color = Colors.deepPurpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
