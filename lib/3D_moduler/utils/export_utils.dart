import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

/// Utility class for exporting canvas content and sharing.
class ExportUtils {
  ExportUtils._();

  /// Captures the widget tree under [key] as a PNG byte array.
  /// [pixelRatio] controls output resolution (2.0 = 2× screen resolution).
  static Future<Uint8List?> captureWidgetToPng(
    GlobalKey key, {
    double pixelRatio = 2.0,
  }) async {
    try {
      final boundary = key.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('ExportUtils.captureWidgetToPng error: $e');
      return null;
    }
  }

  /// Saves [bytes] as a PNG file in the app's temp directory and returns the path.
  static Future<String?> saveToTempFile(
    Uint8List bytes, {
    String filename = 'window_design',
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/${filename}_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('ExportUtils.saveToTempFile error: $e');
      return null;
    }
  }

  /// Saves PNG to Documents folder (more persistent).
  static Future<String?> saveToDocuments(
    Uint8List bytes, {
    String filename = 'window_design',
  }) async {
    try {
      Directory dir;
      try {
        dir = await getApplicationDocumentsDirectory();
      } catch (_) {
        dir = await getTemporaryDirectory();
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/${filename}_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('ExportUtils.saveToDocuments error: $e');
      return null;
    }
  }

  /// Shares [bytes] as a PNG image using the system share sheet.
  static Future<void> shareImage(
    Uint8List bytes, {
    String text = 'My Kintted Wings Window Design',
    String filename = 'window_design',
  }) async {
    try {
      final path = await saveToTempFile(bytes, filename: filename);
      if (path == null) return;
      await Share.shareXFiles(
        [XFile(path, mimeType: 'image/png')],
        text: text,
      );
    } catch (e) {
      debugPrint('ExportUtils.shareImage error: $e');
    }
  }

  /// Shows an export result snackbar.
  static void showExportSnackbar(
    BuildContext context,
    String? filePath, {
    String successMessage = 'Image saved!',
  }) {
    final msg = filePath != null ? successMessage : 'Export failed.';
    final color = filePath != null
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            filePath != null ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
