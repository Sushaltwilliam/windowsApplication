import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '3D_moduler/providers/window_designer_provider.dart';
import '3D_moduler/providers/ar_provider.dart';
import '3D_moduler/ui/designer_screen.dart';
import 'ar_camera/providers/camera_detection_provider.dart';
import 'ar_camera/screens/ar_camera_screen.dart';
import 'mosquito_net/screens/net_designer_screen.dart';
import 'ventilation/screens/vent_designer_screen.dart';
import 'arch_windows/screens/arch_window_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WindowDesignerProvider()),
        ChangeNotifierProvider(create: (_) => ArProvider()),
        ChangeNotifierProvider(create: (_) => CameraDetectionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anraone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F7BF7), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.window_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anraone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Design Studio',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Quick Actions ───────────────────────────────────────────
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.camera_alt_rounded,
                    label: 'AR Camera',
                    color: const Color(0xFF00E676),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ArCameraScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.architecture,
                    label: 'Designer',
                    color: const Color(0xFF4F7BF7),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DesignerScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Product Categories ──────────────────────────────────────
              const Text(
                'PRODUCTS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),

              _ProductCard(
                title: 'Aluminum Windows',
                subtitle:
                    '2D/3D designer with templates, themes,\nAR visualization & export',
                icon: Icons.window_outlined,
                accentColor: const Color(0xFF4F7BF7),
                badge: 'EDITOR',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DesignerScreen()),
                ),
              ),
              const SizedBox(height: 12),

              _ProductCard(
                title: 'Arch Windows',
                subtitle:
                    'Half-round, gothic, elliptical &\ncircle window designs',
                icon: Icons.rounded_corner,
                accentColor: const Color(0xFFAB47BC),
                badge: 'NEW',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArchWindowScreen()),
                ),
              ),
              const SizedBox(height: 12),

              _ProductCard(
                title: 'Mosquito Net Kit',
                subtitle:
                    'Mesh selection, frame type, panel\nconfiguration & measurements',
                icon: Icons.grid_4x4,
                accentColor: const Color(0xFF26A69A),
                badge: 'NEW',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NetDesignerScreen()),
                ),
              ),
              const SizedBox(height: 12),

              _ProductCard(
                title: 'Ventilation',
                subtitle:
                    'Louvers, exhaust frames, trickle vents\n& fixed grilles',
                icon: Icons.air,
                accentColor: const Color(0xFFFF8A65),
                badge: 'NEW',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VentDesignerScreen()),
                ),
              ),
              const SizedBox(height: 32),

              // ── Footer ──────────────────────────────────────────────────
              Center(
                child: Text(
                  'v1.0 • Professional Edition',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.15), fontSize: 11),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? badge;
  final VoidCallback onTap;

  const _ProductCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: Colors.white.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
