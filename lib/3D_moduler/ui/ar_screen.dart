import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/ar_provider.dart';
import '../providers/window_designer_provider.dart';
import '../models/active_window.dart';
import '../utils/export_utils.dart';
import 'ar_canvas_widget.dart';
import 'window_library_sheet.dart';

/// Full-screen AR Visualizer screen.
/// Background photo (or dark canvas) with perspective-warped window placements.
class ArScreen extends StatefulWidget {
  const ArScreen({super.key});

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> with TickerProviderStateMixin {
  final GlobalKey _exportKey = GlobalKey();
  late AnimationController _fabPulseCtrl;
  late Animation<double> _fabPulse;

  // Drag state for moving placement body
  Offset? _dragStart;
  List<Offset>? _cornersAtDragStart;

  @override
  void initState() {
    super.initState();
    _fabPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fabPulse = Tween(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<ArProvider>();
    final designer = context.watch<WindowDesignerProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF080E1A),
      appBar: _buildAppBar(context, ar, designer),
      body: Stack(
        children: [
          // ── AR Canvas ────────────────────────────────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              key: _exportKey,
              child: _buildCanvas(context, ar, designer),
            ),
          ),

          // ── Placement toolbar (when placement selected) ───────────────────
          if (ar.activePlacement != null)
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: _buildPlacementToolbar(context, ar),
            ),

          // ── Bottom window strip ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomStrip(context, ar, designer),
          ),
        ],
      ),

      // ── FAB: Add window ──────────────────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabPulse,
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF4F7BF7),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Place Window',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => _showWindowLibrary(context, ar, designer),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, ArProvider ar,
      WindowDesignerProvider designer) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.55),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('AR Visualizer',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          Text('Place windows on your photo',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Pick photo
        IconButton(
          icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
          tooltip: 'Pick building photo',
          onPressed: () async {
            final ok = await ar.pickPhoto();
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No photo selected')),
              );
            }
          },
        ),
        // Clear photo
        if (ar.backgroundImage != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white54),
            tooltip: 'Clear photo',
            onPressed: ar.clearBackground,
          ),
        // Reset view
        IconButton(
          icon: const Icon(Icons.fit_screen, color: Colors.white),
          tooltip: 'Reset view',
          onPressed: ar.resetTransform,
        ),
        // Export
        IconButton(
          icon: const Icon(Icons.ios_share_outlined, color: Colors.white),
          tooltip: 'Export',
          onPressed: () => _export(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── AR Canvas ────────────────────────────────────────────────────────────
  Widget _buildCanvas(BuildContext context, ArProvider ar,
      WindowDesignerProvider designer) {
    return GestureDetector(
      onTap: ar.deselect,
      onScaleStart: (details) {
        _dragStart = details.focalPoint;
        if (ar.activePlacement != null) {
          _cornersAtDragStart =
              List.from(ar.activePlacement!.perspectiveCorners);
        }
      },
      onScaleUpdate: (details) {
        if (details.pointerCount == 1) {
          // Single finger: move active placement OR pan canvas
          if (ar.activePlacement != null &&
              !ar.activePlacement!.isLocked &&
              _dragStart != null) {
            final delta = details.focalPoint - _dragStart!;
            _dragStart = details.focalPoint;
            ar.translateActivePlacement(delta);
          } else {
            ar.panCanvas(details.focalPointDelta);
          }
        } else if (details.pointerCount >= 2) {
          // Two-finger: pinch-zoom canvas
          ar.zoomCanvas(details.scale, details.localFocalPoint);
        }
      },
      child: ArCanvasWidget(
        ar: ar,
        designer: designer,
        onCornerDrag: (placementId, cornerIndex, newPos) {
          ar.selectPlacement(placementId);
          ar.updateActiveCorner(cornerIndex, newPos);
        },
        onPlacementTap: (placementId) {
          ar.selectPlacement(placementId);
        },
      ),
    );
  }

  // ── Placement Toolbar ────────────────────────────────────────────────────
  Widget _buildPlacementToolbar(BuildContext context, ArProvider ar) {
    final p = ar.activePlacement!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                // Opacity slider
                const Icon(Icons.opacity, color: Colors.white54, size: 16),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      activeTrackColor: const Color(0xFF4F7BF7),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: p.placementOpacity,
                      onChanged: (v) =>
                          ar.setPlacementOpacity(p.id, v),
                    ),
                  ),
                ),
                // Lock
                _iconBtn(
                  p.isLocked ? Icons.lock : Icons.lock_open,
                  p.isLocked ? Colors.amber : Colors.white54,
                  () => ar.lockPlacement(p.id, !p.isLocked),
                  tooltip: p.isLocked ? 'Unlock' : 'Lock',
                ),
                // Delete
                _iconBtn(
                  Icons.delete_outline,
                  const Color(0xFFFF6B6B),
                  () => ar.removePlacement(p.id),
                  tooltip: 'Remove',
                ),
                // Deselect
                _iconBtn(
                  Icons.close,
                  Colors.white38,
                  ar.deselect,
                  tooltip: 'Deselect',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom strip: placed window chips ─────────────────────────────────────
  Widget _buildBottomStrip(BuildContext context, ArProvider ar,
      WindowDesignerProvider designer) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: SafeArea(
            top: false,
            child: ar.placements.isEmpty
                ? Center(
                    child: Text(
                      'Tap "Place Window" to add a window to your photo',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    itemCount: ar.placements.length,
                    itemBuilder: (_, i) {
                      final placement = ar.placements[i];
                      final isActive =
                          placement.id == ar.activePlacementId;
                      // Find the window
                      final window = designer.activeWindows.firstWhere(
                        (w) => w.id == placement.windowId,
                        orElse: () => designer.activeWindows.isNotEmpty
                            ? designer.activeWindows.first
                            : ActiveWindow(
                                id: '',
                                template: designer.templates.first,
                                category: 'Rectangle',
                                theme: WindowDesignerProvider
                                    .availableThemes.first,
                                corners: [],
                                logicalWidth: 100,
                                logicalHeight: 100,
                              ),
                      );
                      return GestureDetector(
                        onTap: () => ar.selectPlacement(placement.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF4F7BF7).withOpacity(0.25)
                                : Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF4F7BF7)
                                  : Colors.white.withOpacity(0.12),
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.window_outlined,
                                  color: isActive
                                      ? const Color(0xFF4F7BF7)
                                      : Colors.white38,
                                  size: 22),
                              const SizedBox(height: 4),
                              Text(
                                window.label.isNotEmpty
                                    ? window.label
                                    : window.template.name
                                        .split(' ')
                                        .first,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap,
      {String tooltip = ''}) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
  }

  void _showWindowLibrary(BuildContext context, ArProvider ar,
      WindowDesignerProvider designer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WindowLibrarySheet(
        designer: designer,
        onWindowSelected: (window) {
          // Add the window to the designer if not already there
          if (!designer.activeWindows.any((w) => w.id == window.id)) {
            designer.activeWindows.add(window);
          }
          final size = MediaQuery.of(context).size;
          ar.addPlacement(windowId: window.id, canvasSize: size);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final bytes = await ExportUtils.captureWidgetToPng(_exportKey);
    if (bytes == null) {
      if (context.mounted) {
        ExportUtils.showExportSnackbar(context, null,
            successMessage: 'Export failed');
      }
      return;
    }
    final path = await ExportUtils.saveToDocuments(bytes,
        filename: 'ar_window_design');
    if (context.mounted) {
      ExportUtils.showExportSnackbar(context, path,
          successMessage: 'Design saved!');
    }
    await ExportUtils.shareImage(bytes, text: 'My Kintted Wings AR Design');
  }
}
