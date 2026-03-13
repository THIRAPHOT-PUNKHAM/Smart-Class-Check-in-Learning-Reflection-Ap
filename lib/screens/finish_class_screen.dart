import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app.dart';

/// FinishClassScreen
/// -----------------
/// Handles the full Check-out (Finish Class) flow:
///   1. GPS location captured automatically on screen open
///   2. End-of-session QR Code scanned
///   3. Post-class reflection form (learned today, feedback)
///
/// All steps must complete and the form must be valid before saving.
/// Saves to SQLite then attempts background Firebase sync.

class FinishClassScreen extends StatefulWidget {
  final String studentId;
  final int checkinId; // Foreign key linking this check-out to its check-in

  const FinishClassScreen({
    super.key,
    required this.studentId,
    required this.checkinId,
  });

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  // Form
  final _formKey = GlobalKey<FormState>();
  final _learnedController  = TextEditingController();
  final _feedbackController = TextEditingController();

  // GPS
  Position? _position;
  bool _isGpsLoading = false;
  String? _gpsError;

  // QR
  String? _qrCode;
  String? _qrError;

  // UI
  bool _isSaving = false;

  final _locationService = LocationService();

  // ── Lifecycle ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _captureGps();
  }

  @override
  void dispose() {
    _learnedController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────

  Future<void> _captureGps() async {
    setState(() {
      _isGpsLoading = true;
      _gpsError = null;
    });
    try {
      final pos = await _locationService.getCurrentPosition();
      if (mounted) setState(() => _position = pos);
    } catch (e) {
      if (mounted) setState(() => _gpsError = e.toString());
    } finally {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  // ── QR Scan ──────────────────────────────────────────────────────

  Future<void> _scanQr() async {
    setState(() => _qrError = null);
    try {
      final code = await QrScannerService.scanQrCode(context);
      if (!mounted) return;
      if (code != null && code.isNotEmpty) {
        setState(() => _qrCode = code);
      } else {
        setState(() => _qrError = 'QR scan cancelled or empty — try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _qrError = e.toString());
    }
  }

  // ── Save ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_position == null) {
      _showSnack('Please capture GPS location first.', isError: true);
      return;
    }
    if (_qrCode == null || _qrCode!.trim().isEmpty) {
      _showSnack('Please scan the end-of-session QR code first.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final record = CheckOutRecord(
        checkinId:        widget.checkinId,
        checkoutTime:     DateTime.now(),
        checkoutGpsLat:   _position!.latitude,
        checkoutGpsLng:   _position!.longitude,
        qrCodeCheckout:   _qrCode!.trim(),
        learnedToday:     _learnedController.text.trim(),
        feedback:         _feedbackController.text.trim(),
      );

      final id = await DatabaseService.instance.insertCheckOut(record);

      // Fire-and-forget Firebase sync
      FirebaseSyncService.instance.syncCheckOut(record.copyWith(id: id));

      if (mounted) {
        _showSnack('Class finished and saved! 🎓');
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showSnack('Error saving: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finish Class'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student chip + session info banner
            _buildSessionBanner(),
            const SizedBox(height: 24),

            // ── Step 1: GPS ──────────────────────────────────────
            _StepHeader(
              step: '1',
              icon: Icons.location_on_rounded,
              title: 'Capture GPS Location',
            ),
            const SizedBox(height: 12),
            _buildGpsCard(),
            const SizedBox(height: 24),

            // ── Step 2: QR ───────────────────────────────────────
            _StepHeader(
              step: '2',
              icon: Icons.qr_code_scanner,
              title: 'Scan End-of-Session QR Code',
            ),
            const SizedBox(height: 12),
            _buildQrCard(),
            const SizedBox(height: 24),

            // ── Step 3: Post-class reflection ─────────────────────
            _StepHeader(
              step: '3',
              icon: Icons.rate_review_rounded,
              title: 'Post-class Reflection',
            ),
            const SizedBox(height: 12),
            _buildReflectionForm(),
            const SizedBox(height: 32),

            // ── Save ──────────────────────────────────────────────
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Session banner ────────────────────────────────────────────────

  Widget _buildSessionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondary.withValues(alpha: 0.15),
            AppTheme.primary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.logout_rounded, color: AppTheme.secondary, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Finishing class session',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Student: ${widget.studentId}  •  Session #${widget.checkinId}',
                style: const TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── GPS card ──────────────────────────────────────────────────────

  Widget _buildGpsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isGpsLoading
              ? const _GpsLoading(key: ValueKey('loading'))
              : _position != null
                  ? _GpsSuccess(
                      key: const ValueKey('success'),
                      position: _position!,
                      onRetry: _captureGps,
                    )
                  : _GpsError(
                      key: const ValueKey('error'),
                      errorMsg: _gpsError,
                      onRetry: _captureGps,
                    ),
        ),
      ),
    );
  }

  // ── QR card ───────────────────────────────────────────────────────

  Widget _buildQrCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _qrCode != null
            ? Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppTheme.success,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End QR scanned ✓',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _qrCode!,
                          style: const TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _scanQr,
                    child: const Text('Rescan'),
                  ),
                ],
              )
            : Column(
                children: [
                  if (_qrError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _qrError!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _scanQr,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan End-of-Session QR'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Reflection form ───────────────────────────────────────────────

  Widget _buildReflectionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // What I learned
              TextFormField(
                controller: _learnedController,
                decoration: const InputDecoration(
                  labelText: 'What did you learn today? *',
                  hintText: 'e.g. How to use StatefulWidget and setState',
                  prefixIcon: Icon(Icons.school_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'This field is required'
                        : null,
              ),
              const SizedBox(height: 16),

              // Feedback
              TextFormField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback about the class or instructor *',
                  hintText: 'e.g. More examples would help; great pace!',
                  prefixIcon: Icon(Icons.feedback_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'This field is required'
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final allReady = _position != null && _qrCode != null;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                allReady
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
              ),
        label: Text(_isSaving ? 'Saving…' : 'Finish & Save'),
        style: ElevatedButton.styleFrom(
          backgroundColor: allReady ? AppTheme.secondary : AppTheme.surfaceVariant,
          foregroundColor: allReady ? Colors.black87 : AppTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Shared step widgets (re-exported for clarity)
// ════════════════════════════════════════════════════════════════════

class _StepHeader extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;

  const _StepHeader({
    required this.step,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GpsLoading extends StatelessWidget {
  const _GpsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        SizedBox(width: 14),
        Text(
          'Capturing GPS location…',
          style: TextStyle(color: AppTheme.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _GpsSuccess extends StatelessWidget {
  final Position position;
  final VoidCallback onRetry;

  const _GpsSuccess({super.key, required this.position, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppTheme.success,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location captured ✓',
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                LocationService.formatPosition(position),
                style: const TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _GpsError extends StatelessWidget {
  final String? errorMsg;
  final VoidCallback onRetry;

  const _GpsError({super.key, required this.errorMsg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMsg ?? 'Failed to get location.',
                style: const TextStyle(color: AppTheme.error, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Retry GPS Capture'),
          ),
        ),
      ],
    );
  }
}
