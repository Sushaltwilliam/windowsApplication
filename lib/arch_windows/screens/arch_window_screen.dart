import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../3D_moduler/providers/window_designer_provider.dart';
import '../../3D_moduler/ui/designer_screen.dart';

class ArchWindowScreen extends StatelessWidget {
  const ArchWindowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Arch Windows',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFAB47BC).withOpacity(0.15),
                      const Color(0xFF7B1FA2).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFAB47BC).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAB47BC).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.rounded_corner,
                          color: Color(0xFFAB47BC), size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Arched Window Designs',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select a template and customize in the designer',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Templates grid
              const Text(
                'ARCH TEMPLATES',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              _TemplateGrid(templates: _archTemplates),
              const SizedBox(height: 28),

              // Open full designer button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DesignerScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFAB47BC), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.open_in_new,
                      color: Color(0xFFAB47BC), size: 18),
                  label: const Text(
                    'Open Full Designer',
                    style: TextStyle(
                        color: Color(0xFFAB47BC), fontWeight: FontWeight.w600),
                  ),
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

// ── Arch templates ──────────────────────────────────────────────────────────
final List<_ArchTemplate> _archTemplates = [
  _ArchTemplate(
    name: 'Half-Round Top',
    description: 'Classic arch with rectangular base',
    icon: Icons.rounded_corner,
    templateId: 'arched_top',
  ),
  _ArchTemplate(
    name: 'Gothic Arch',
    description: 'Pointed arch, cathedral style',
    icon: Icons.church,
    templateId: 'arched_top',
  ),
  _ArchTemplate(
    name: 'Eyebrow Arch',
    description: 'Subtle curved top',
    icon: Icons.visibility,
    templateId: 'arched_top',
  ),
  _ArchTemplate(
    name: 'Full Circle',
    description: 'Complete round window',
    icon: Icons.circle_outlined,
    templateId: 'circle_plain',
  ),
  _ArchTemplate(
    name: 'Elliptical',
    description: 'Oval-shaped window',
    icon: Icons.panorama_horizontal,
    templateId: 'circle_plain',
  ),
  _ArchTemplate(
    name: 'Segmented Arch',
    description: 'Arch with mullion divisions',
    icon: Icons.auto_awesome_mosaic,
    templateId: 'arched_top',
  ),
];

class _ArchTemplate {
  final String name;
  final String description;
  final IconData icon;
  final String templateId;

  const _ArchTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.templateId,
  });
}

// ── Template Grid ───────────────────────────────────────────────────────────
class _TemplateGrid extends StatelessWidget {
  final List<_ArchTemplate> templates;
  const _TemplateGrid({required this.templates});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: templates.length,
      itemBuilder: (ctx, i) => _TemplateCard(
        template: templates[i],
        onTap: () => _openDesigner(context, templates[i]),
      ),
    );
  }

  void _openDesigner(BuildContext context, _ArchTemplate archTemplate) {
    final provider =
        Provider.of<WindowDesignerProvider>(context, listen: false);
    // Find the matching template
    final template = provider.templates.firstWhere(
      (t) => t.id == archTemplate.templateId,
      orElse: () => provider.templates.first,
    );

    provider.addWindow(
      template: template,
      canvasSize: MediaQuery.of(context).size,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DesignerScreen()),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _ArchTemplate template;
  final VoidCallback onTap;
  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFAB47BC).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(template.icon,
                    color: const Color(0xFFAB47BC), size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                template.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                template.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white30, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
