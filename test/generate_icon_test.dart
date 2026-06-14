import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate Logo PNG', () async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 512, 512));

    // Background
    final bgPaint = Paint()..color = const Color(0xFF0D0D0D)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 512, 512), const Radius.circular(128)), bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 24, 464, 464), const Radius.circular(104)), borderPaint);

    // Left Leaf (shadowed page)
    final leftPath = Path()
      ..moveTo(256, 160)
      ..lineTo(140, 210)
      ..lineTo(140, 350)
      ..lineTo(256, 300)
      ..close();
    final leftPaint = Paint()
      ..color = const Color(0xFF888888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(leftPath, leftPaint);

    // Right Leaf (main page)
    final rightPath = Path()
      ..moveTo(256, 160)
      ..lineTo(372, 210)
      ..lineTo(372, 350)
      ..lineTo(256, 300)
      ..close();
    final rightPaint = Paint()
      ..color = const Color(0xFFEBE9DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(rightPath, rightPaint);

    // Hanging Bookmark
    final bookmarkPath = Path()
      ..moveTo(256, 300)
      ..lineTo(256, 420);
    canvas.drawPath(bookmarkPath, rightPaint);

    // Accent line
    final accentPath = Path()
      ..moveTo(314, 235)
      ..lineTo(314, 285);
    final accentPaint = Paint()
      ..color = const Color(0xFFEBE9DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(accentPath, accentPaint);

    // Export to PNG
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(512, 512);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final file = File('assets/logo.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}