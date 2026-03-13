import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// QrScannerService
/// ----------------
/// Provides helpers for QR-code scanning using the mobile_scanner package.
///
/// Key responsibilities:
///   1. Check and request Camera permission at runtime (NFR requirement).
///   2. Expose a full-screen QR scan page that callers can push via Navigator.
///   3. Return the scanned QR code string to the calling screen.
///
/// Usage (inside a button handler):
///   final result = await QrScannerService.scanQrCode(context);
///   if (result != null) {
///     // result is the scanned QR string
///   }

class QrScannerService {
  // ------------------------------------------------------------------
  // Permission check
  // ------------------------------------------------------------------

  /// Returns true if camera permission is granted.
  /// Requests permission if not yet determined.
  /// Throws [CameraPermissionDeniedException] if permanently denied.
  static Future<bool> checkAndRequestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied) {
      throw const CameraPermissionDeniedException(
        'Camera permission is permanently denied. '
        'Please enable it in Settings.',
      );
    }

    return status.isGranted;
  }

  // ------------------------------------------------------------------
  // Launch scanner page
  // ------------------------------------------------------------------

  /// Checks camera permission then pushes [QrScanPage] onto the Navigator.
  ///
  /// Returns the scanned QR code [String] or null if the user cancels.
  ///
  /// Example:
  /// ```dart
  /// final code = await QrScannerService.scanQrCode(context);
  /// if (code != null) { /* use code */ }
  /// ```
  static Future<String?> scanQrCode(BuildContext context) async {
    final permitted = await checkAndRequestCameraPermission();
    if (!permitted) return null; // Permission denied — cannot open camera.

    if (!context.mounted) return null;

    return Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
  }
}

// ====================================================================
// QrScanPage — Full-screen scanner UI
// ====================================================================

/// A full-screen camera view that scans a QR code and automatically
/// pops the route with the decoded string value.
///
/// The caller receives the result via [Navigator.push].
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false; // Prevent duplicate callbacks

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Only process the first detected barcode.
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _hasScanned = true;
    // Pop back to the calling screen and return the QR value.
    Navigator.of(context).pop(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          // Torch toggle
          IconButton(
            icon: const Icon(Icons.flashlight_on),
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
          ),
          // Camera flip
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // -- Camera feed --
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // -- Overlay: scanning frame hint --
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // -- Instruction label --
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point the camera at the classroom QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}

// ------------------------------------------------------------------
// Custom exception
// ------------------------------------------------------------------

/// Thrown when the user permanently refuses camera access.
class CameraPermissionDeniedException implements Exception {
  final String message;
  const CameraPermissionDeniedException(this.message);

  @override
  String toString() => 'CameraPermissionDeniedException: $message';
}
