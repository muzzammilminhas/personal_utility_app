// ============================================================
//  screens/qr_card/qr_scanner_screen.dart  –  QR Camera Scanner
// ============================================================
//
//  This screen opens the device camera to scan QR codes.
//  It uses the `mobile_scanner` package which gives us a live
//  camera preview widget that detects QR/barcodes in real-time.
//
//  Flow:
//  1. Screen opens → camera starts → live preview shown
//  2. User points camera at QR code
//  3. MobileScanner calls onDetect() with the decoded data
//  4. We save the scanned text to Supabase via provider
//  5. Pop back and pass the scanned text to the caller
//
//  NOTE: Camera permission must be granted. The app requests
//  this automatically when MobileScanner is instantiated.
//  Make sure CAMERA permission is in AndroidManifest.xml
//  (already done in Part 1).
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/business_card_provider.dart';
import '../../utils/app_constants.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // ── MobileScannerController manages the camera lifecycle ──
  // It gives us: start(), stop(), toggleTorch(), switchCamera()
  final MobileScannerController _controller = MobileScannerController(
    // Only detect QR codes (not all barcode types)
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // Track whether a QR has already been detected this session
  // to prevent scanning the same code multiple times rapidly
  bool _hasScanned = false;

  @override
  void dispose() {
    // Always dispose the scanner to release the camera resource
    _controller.dispose();
    super.dispose();
  }

  // ── Handle a detected barcode ──────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    // Ignore if we already processed one scan
    if (_hasScanned) return;

    // Get the first barcode from the captured list
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    // Mark as scanned to prevent duplicate processing
    setState(() => _hasScanned = true);

    // Stop the camera immediately after successful scan
    await _controller.stop();

    if (!mounted) return;

    // Save to Supabase scan history via provider
    await context.read<BusinessCardProvider>().saveScan(rawValue);

    if (!mounted) return;

    // Show a brief success banner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code scanned and saved to history!'),
        duration: Duration(seconds: 2),
      ),
    );

    // Return the scanned text to the calling screen
    // Navigator.pop(context, value) passes data back
    Navigator.pop(context, rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // ── Torch toggle ───────────────────────────────────
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: _controller.toggleTorch,
                tooltip: 'Toggle flashlight',
              );
            },
          ),
          // ── Flip camera ────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _controller.switchCamera,
            tooltip: 'Flip camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera Preview ─────────────────────────────────
          // MobileScanner fills the screen with a live feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Scanner Overlay ────────────────────────────────
          // A visual guide to show the user where to aim
          _buildScannerOverlay(),

          // ── Bottom Instructions ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Text(
                'Align the QR code within the frame to scan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scanner Overlay ─────────────────────────────────────────
  //  A custom-painted overlay with a transparent "viewfinder"
  //  square in the center, surrounded by a semi-transparent
  //  dark overlay. Corner decorations show the scan area.
  Widget _buildScannerOverlay() {
    return CustomPaint(
      painter: _ScannerOverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

// ── _ScannerOverlayPainter ────────────────────────────────────
//  CustomPainter draws the dark overlay with a clear window.
//  This demonstrates the CustomPainter API in Flutter.
// ─────────────────────────────────────────────────────────────
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    // Size of the clear scanning window
    const scanWindowSize = 260.0;
    final scanWindowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    // Draw the dark overlay using path operations:
    // Full screen path MINUS the scan window = dark border
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          scanWindowRect, const Radius.circular(12)))
      // fillType.evenOdd creates a "hole" in the overlay
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner decorations (L-shaped brackets)
    _drawCorners(canvas, scanWindowRect);
  }

  void _drawCorners(Canvas canvas, Rect rect) {
    const cornerLength = 24.0;
    const cornerWidth = 4.0;
    final cornerPaint = Paint()
      ..color = ModuleColors.qrCard
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLength), cornerPaint);

    // Top-right corner
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLength), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLength), cornerPaint);
  }

  // repaint returns false because this overlay never changes
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}