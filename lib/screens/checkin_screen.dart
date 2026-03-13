import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app.dart';

/// CheckinScreen
/// -------------
/// Handles the full Check-in flow (Step 1 → Step 2 → Step 3 → Save):
///   1. GPS location captured automatically on screen open
///   2. Classroom QR Code scanned by the student
///   3. Pre-class reflection form (previous topic, expected topic, mood 1–5)
///
/// All three steps must be completed and the form validated before the
/// Save button becomes fully active. Saves to SQLite then attempts
/// a background Firebase sync.

class CheckinScreen extends StatefulWidget {
  final String studentId;

  const CheckinScreen({super.key, required this.studentId});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  // Form
  final _formKey = GlobalKey<FormState>();
  final _prevTopicController    = TextEditingController();
  final _expectedTopicController = TextEditingController();
  int _selectedMood = 0; // 0 = not selected

  // GPS
  Position? _position;
  bool _isGpsLoading = false;
  String? _gpsError;

  // QR
  String? _qrCode;
  String? _qrError;

  // UI state
  bool _isSaving = false;

  final _locationService = LocationService();

  // ── Lifecycle ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _captureGps(); // Auto-capture GPS on open
  }

  @override
  void dispose() {
    _prevTopicController.dispose();
    _expectedTopicController.dispose();
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
    // --- Guard checks ---
    if (_position == null) {
      _showSnack('Please capture GPS location first.', isError: true);
      return;
    }
    if (_qrCode == null || _qrCode!.trim().isEmpty) {
      _showSnack('Please scan the classroom QR code first.', isError: true);
      return;
    }
    if (_selectedMood == 0) {
      _showSnack('Please select your mood before class.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final record = CheckInRecord(
        studentId:     widget.studentId,
        checkinTime:   DateTime.now(),
        checkinGpsLat: _position!.latitude,
        checkinGpsLng: _position!.longitude,
        qrCodeCheckin: _qrCode!.trim(),
        prevTopic:     _prevTopicController.text.trim(),
        expectedTopic: _expectedTopicController.text.trim(),
        moodBefore:    _selectedMood,
      );

      // Persist locally
      final id = await DatabaseService.instance.insertCheckIn(record);

      // Try remote sync (fire-and-forget; errors logged internally)
      FirebaseSyncService.instance.syncCheckIn(record.copyWith(id: id));

      if (mounted) {
        _showSnack('Check-in saved successfully! ✅');
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
        title: const Text('Check-in'),
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
            // Student chip
            _StudentChip(studentId: widget.studentId),
            const SizedBox(height: 24),

            // ── Step 1: GPS ──────────────────────────────────────
            _StepHeader(step: '1', icon: Icons.location_on_rounded, title: 'Capture GPS Location'),
            const SizedBox(height: 12),
            _buildGpsCard(),
            const SizedBox(height: 24),

            // ── Step 2: QR ───────────────────────────────────────
            _StepHeader(step: '2', icon: Icons.qr_code_scanner, title: 'Scan Classroom QR Code'),
            const SizedBox(height: 12),
            _buildQrCard(),
            const SizedBox(height: 24),

            // ── Step 3: Reflection form ───────────────────────────
            _StepHeader(step: '3', icon: Icons.edit_note_rounded, title: 'Pre-class Reflection'),
            const SizedBox(height: 12),
            _buildReflectionForm(),
            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
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
              ? _GpsLoading(key: const ValueKey('loading'))
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
                  const Icon(Icons.qr_code_2_rounded, color: AppTheme.success, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QR Code scanned ✓',
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
                      label: const Text('Scan QR Code'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Previous topic
              TextFormField(
                controller: _prevTopicController,
                decoration: const InputDecoration(
                  labelText: 'What was covered in the previous class? *',
                  hintText: 'e.g. Introduction to Flutter widgets',
                  prefixIcon: Icon(Icons.history_edu_rounded),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 16),

              // Expected topic
              TextFormField(
                controller: _expectedTopicController,
                decoration: const InputDecoration(
                  labelText: 'What do you expect to learn today? *',
                  hintText: 'e.g. State management with Provider',
                  prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 20),

              // Mood selector
              const Text(
                'How are you feeling before class? *',
                style: TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              _MoodSelector(
                selectedMood: _selectedMood,
                onMoodSelected: (v) => setState(() => _selectedMood = v),
              ),
              if (_selectedMood == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Please select your mood',
                    style: TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final allReady = _position != null && _qrCode != null && _selectedMood != 0;

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
                allReady ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              ),
        label: Text(_isSaving ? 'Saving…' : 'Save Check-in'),
        style: ElevatedButton.styleFrom(
          backgroundColor: allReady ? AppTheme.primary : AppTheme.surfaceVariant,
          foregroundColor: allReady ? Colors.white : AppTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Private sub-widgets (shared logic kept close to usage)
// ════════════════════════════════════════════════════════════════════

class _StudentChip extends StatelessWidget {
  final String studentId;
  const _StudentChip({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            studentId,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// GPS sub-states
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
        const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
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
            const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 26),
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

// Mood selector row
class _MoodSelector extends StatelessWidget {
  final int selectedMood;
  final ValueChanged<int> onMoodSelected;

  static const _moods = [
    {'emoji': '😡', 'label': 'Very\nNeg', 'score': 1},
    {'emoji': '🙁', 'label': 'Neg',       'score': 2},
    {'emoji': '😐', 'label': 'Neutral',   'score': 3},
    {'emoji': '🙂', 'label': 'Pos',       'score': 4},
    {'emoji': '😄', 'label': 'Very\nPos', 'score': 5},
  ];

  const _MoodSelector({
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _moods.map((mood) {
        final score = mood['score'] as int;
        final selected = selectedMood == score;

        return GestureDetector(
          onTap: () => onMoodSelected(score),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mood['emoji'] as String,
                  style: TextStyle(fontSize: selected ? 34 : 26),
                ),
                const SizedBox(height: 4),
                Text(
                  score.toString(),
                  style: TextStyle(
                    color: selected ? AppTheme.primary : AppTheme.onSurfaceMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
