import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors.dart';
import '../../../providers/home_tile_order_provider.dart';
import '../../components/sisu_tile_card.dart';
import '../home_modules.dart';

/// Home-grid cell: tap to open, long-press to jiggle + drag reorder (#351).
class HomeModuleTile extends ConsumerWidget {
  final HomeModule module;
  final int index;
  final bool editing;

  const HomeModuleTile({
    super.key,
    required this.module,
    required this.index,
    required this.editing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final face = _HomeAppTile(
          module: module,
          onTap: editing ? null : () => context.push(module.route),
        );
        return DragTarget<String>(
          onWillAcceptWithDetails: (details) => details.data != module.id,
          onAcceptWithDetails: (details) {
            ref
                .read(homeTileOrderProvider.notifier)
                .moveIdTo(details.data, index);
          },
          builder: (context, candidate, rejected) {
            final hovering = candidate.isNotEmpty;
            return LongPressDraggable<String>(
              data: module.id,
              hapticFeedbackOnStart: true,
              delay: editing
                  ? const Duration(milliseconds: 180)
                  : const Duration(milliseconds: 450),
              onDragStarted: () {
                ref.read(homeTileEditModeProvider.notifier).enter();
              },
              feedback: Material(
                color: Colors.transparent,
                elevation: 8,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Transform.scale(
                    scale: 1.06,
                    child: _HomeAppTile(module: module, onTap: null),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: face),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: hovering
                      ? Border.all(
                          color: SisuColors.getTextPrimaryColor(
                            Theme.of(context).brightness == Brightness.dark,
                          ).withValues(alpha: 0.55),
                          width: 2,
                        )
                      : null,
                ),
                child: HomeTileJiggle(
                  enabled: editing,
                  phaseSeed: module.id.hashCode,
                  child: face,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HomeTileJiggle extends StatefulWidget {
  final bool enabled;
  final int phaseSeed;
  final Widget child;

  const HomeTileJiggle({
    super.key,
    required this.enabled,
    required this.phaseSeed,
    required this.child,
  });

  @override
  State<HomeTileJiggle> createState() => _HomeTileJiggleState();
}

class _HomeTileJiggleState extends State<HomeTileJiggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(HomeTileJiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final phase = (widget.phaseSeed % 7) * 0.45;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = math.sin((_controller.value * 2 * math.pi) + phase);
        return Transform.rotate(angle: 0.04 * t, child: child);
      },
      child: widget.child,
    );
  }
}

class _HomeAppTile extends StatelessWidget {
  final HomeModule module;
  final VoidCallback? onTap;

  const _HomeAppTile({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SisuTileCard(
      elevation: 4,
      color: SisuColors.getHomeTile(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module.icon, size: 36, color: module.accent),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                module.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: SisuColors.getTextPrimaryColor(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
