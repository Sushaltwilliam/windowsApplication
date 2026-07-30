import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '3D_moduler/providers/window_designer_provider.dart';
import '3D_moduler/providers/ar_provider.dart';
import '3D_moduler/ui/designer_screen.dart';
import 'ar_camera/providers/camera_detection_provider.dart';
import 'ar_camera/screens/ar_camera_screen.dart';

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
      title: 'Kintted Wings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const RootSelectionScreen(),
    );
  }
}

class RootSelectionScreen extends StatelessWidget {
  const RootSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F7BF7), Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F7BF7)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(Icons.window_outlined,
                            color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Kintted Wings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Aluminum Window & Door Design Studio',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _ModuleCard(
                              icon: Icons.camera_alt_rounded,
                              title: 'AR Detection',
                              subtitle:
                                  'Point camera at windows & doors\nAuto-detect and design in real-time',
                              accentColor: const Color(0xFF00FF00),
                              badge: 'CAMERA',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ArCameraScreen()),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ModuleCard(
                              icon: Icons.architecture,
                              title: 'Window Designer',
                              subtitle:
                                  '2D technical drawings & 3D preview\nDesign aluminum window layouts',
                              accentColor: const Color(0xFF4F7BF7),
                              badge: 'EDITOR',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DesignerScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24, top: 24),
                        child: Text(
                          'v1.0 • Professional Edition',
                          style: TextStyle(color: Colors.white24, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badge;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: accentColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
