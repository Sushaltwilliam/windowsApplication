import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/detected_frame.dart';
import '../providers/camera_detection_provider.dart';

/// Bottom panel for selected pane controls
class FrameControlsPanel extends StatefulWidget {
  const FrameControlsPanel({super.key});

  @override
  State<FrameControlsPanel> createState() => _FrameControlsPanelState();
}

class _FrameControlsPanelState extends State<FrameControlsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraDetectionProvider>(
      builder: (ctx, p, _) {
        final pane = p.selected;
        if (pane == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              _Header(pane: pane, provider: p),
              TabBar(
                controller: _tabs,
                indicatorColor: pane.color,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white30,
                labelStyle:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'SIZE'),
                  Tab(text: 'ANGLE'),
                  Tab(text: 'COLOR')
                ],
              ),
              SizedBox(
                height: 90,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _SizeTab(pane: pane, p: p),
                    _AngleTab(pane: pane, p: p),
                    _ColorTab(pane: pane, p: p),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final PaneBox pane;
  final CameraDetectionProvider provider;
  const _Header({required this.pane, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: pane.color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('${pane.realWidthMm.toInt()}×${pane.realHeightMm.toInt()} mm',
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          _Ico(Icons.add_box_outlined, () {
            provider.deselect();
            provider.startDetection();
          }, color: const Color(0xFF00FF00)),
          _Ico(Icons.copy, () => provider.duplicateSelected()),
          _Ico(pane.isLocked ? Icons.lock : Icons.lock_open_outlined,
              () => provider.toggleLock(pane.id),
              active: pane.isLocked),
          _Ico(Icons.delete_outline, () => provider.deleteSelected(),
              color: Colors.redAccent),
        ],
      ),
    );
  }
}

class _Ico extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? color;
  const _Ico(this.icon, this.onTap, {this.active = false, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(icon,
              size: 16,
              color: color ??
                  (active ? const Color(0xFF00FF00) : Colors.white54))),
    );
  }
}

// ── SIZE ────────────────────────────────────────────────────────────────────
class _SizeTab extends StatelessWidget {
  final PaneBox pane;
  final CameraDetectionProvider p;
  const _SizeTab({required this.pane, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          _Sl(
              label: 'Width',
              value: pane.width,
              min: 30,
              max: 400,
              color: const Color(0xFF64C8FA),
              onChanged: (v) => p.setWidth(pane.id, v)),
          _Sl(
              label: 'Height',
              value: pane.height,
              min: 30,
              max: 500,
              color: const Color(0xFF4DD0C8),
              onChanged: (v) => p.setHeight(pane.id, v)),
          _Sl(
              label: 'W mm',
              value: pane.realWidthMm,
              min: 100,
              max: 3000,
              color: Colors.white24,
              onChanged: (v) => p.setRealWidth(pane.id, v)),
        ],
      ),
    );
  }
}

// ── ANGLE ───────────────────────────────────────────────────────────────────
class _AngleTab extends StatelessWidget {
  final PaneBox pane;
  final CameraDetectionProvider p;
  const _AngleTab({required this.pane, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          _Sl(
              label: 'Rotate',
              value: pane.rotation.clamp(-180, 180),
              min: -180,
              max: 180,
              color: const Color(0xFF00FF00),
              suffix: '°',
              onChanged: (v) => p.setRotation(pane.id, v)),
          _Sl(
              label: 'Tilt X',
              value: pane.tiltX,
              min: -60,
              max: 60,
              color: const Color(0xFFFF6B35),
              suffix: '°',
              onChanged: (v) => p.setTiltX(pane.id, v)),
          _Sl(
              label: 'Tilt Y',
              value: pane.tiltY,
              min: -60,
              max: 60,
              color: const Color(0xFF64C8FA),
              suffix: '°',
              onChanged: (v) => p.setTiltY(pane.id, v)),
        ],
      ),
    );
  }
}

// ── COLOR ───────────────────────────────────────────────────────────────────
class _ColorTab extends StatelessWidget {
  final PaneBox pane;
  final CameraDetectionProvider p;
  const _ColorTab({required this.pane, required this.p});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PaneColors.palette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = PaneColors.palette[i];
                return GestureDetector(
                  onTap: () => p.setColor(pane.id, c),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: pane.color == c
                              ? Colors.white
                              : Colors.transparent,
                          width: 2),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          _Sl(
              label: 'Opacity',
              value: pane.opacity,
              min: 0.1,
              max: 1.0,
              color: pane.color,
              onChanged: (v) => p.setOpacity(pane.id, v)),
        ],
      ),
    );
  }
}

// ── Slider ──────────────────────────────────────────────────────────────────
class _Sl extends StatelessWidget {
  final String label;
  final double value, min, max;
  final Color color;
  final String? suffix;
  final ValueChanged<double> onChanged;
  const _Sl(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.color,
      this.suffix,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          SizedBox(
              width: 38,
              child: Text(label,
                  style: const TextStyle(color: Colors.white30, fontSize: 9))),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: color,
                inactiveTrackColor: Colors.white10,
                thumbColor: color,
              ),
              child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged),
            ),
          ),
          SizedBox(
              width: 30,
              child: Text('${value.toInt()}${suffix ?? ''}',
                  style: const TextStyle(color: Colors.white24, fontSize: 8),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
