import 'package:flutter/material.dart';

class PerspectiveUtils {
  /// Calculates a 4x4 perspective transformation matrix mapping a rectangle `srcBox`
  /// to an arbitrary 4-point quadrilateral `dstPoints`.
  /// 
  /// The [dstPoints] should list the 4 mapped corners in this order:
  /// 0: Top-Left
  /// 1: Top-Right
  /// 2: Bottom-Right
  /// 3: Bottom-Left
  static Matrix4 getPerspectiveTransform(Rect srcBox, List<Offset> dstPoints) {
    if (dstPoints.length != 4) return Matrix4.identity();
    
    double x0 = dstPoints[0].dx;
    double y0 = dstPoints[0].dy;
    double x1 = dstPoints[1].dx;
    double y1 = dstPoints[1].dy;
    double x2 = dstPoints[2].dx;
    double y2 = dstPoints[2].dy;
    double x3 = dstPoints[3].dx;
    double y3 = dstPoints[3].dy;
    
    double dx1 = x1 - x2;
    double dx2 = x3 - x2;
    double dx3 = x0 - x1 + x2 - x3;

    double dy1 = y1 - y2;
    double dy2 = y3 - y2;
    double dy3 = y0 - y1 + y2 - y3;

    double a11, a12, a13, a21, a22, a23, a31, a32;

    if (dx3 == 0.0 && dy3 == 0.0) {
      // Affine transform (parallelogram)
      a11 = x1 - x0;
      a21 = x2 - x1;
      a31 = x0;
      a12 = y1 - y0;
      a22 = y2 - y1;
      a32 = y0;
      a13 = 0.0;
      a23 = 0.0;
    } else {
      // Perspective transform
      double det1 = dx1 * dy2 - dy1 * dx2;
      double det2 = dx3 * dy2 - dy3 * dx2;
      double det3 = dx1 * dy3 - dy1 * dx3;

      a13 = (det1 == 0.0) ? 0.0 : det2 / det1;
      a23 = (det1 == 0.0) ? 0.0 : det3 / det1;
      
      a11 = x1 - x0 + a13 * x1;
      a21 = x3 - x0 + a23 * x3;
      a31 = x0;
      
      a12 = y1 - y0 + a13 * y1;
      a22 = y3 - y0 + a23 * y3;
      a32 = y0;
    }

    // `Matrix4` constructor uses column-major order:
    final Matrix4 pTransform = Matrix4(
      a11, a12, 0.0, a13,  // Column 0
      a21, a22, 0.0, a23,  // Column 1
      0.0, 0.0, 1.0, 0.0,  // Column 2
      a31, a32, 0.0, 1.0,  // Column 3
    );

    // Initial scale matrix to map from physical pixels to 0..1 unit square
    final Matrix4 scaleMatrix = Matrix4.identity()
      ..scale(1.0 / srcBox.width, 1.0 / srcBox.height, 1.0);

    return pTransform * scaleMatrix;
  }
}
