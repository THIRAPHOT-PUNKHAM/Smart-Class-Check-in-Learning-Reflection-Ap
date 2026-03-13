import 'package:flutter/material.dart';

import '../app.dart';

/// HomeScreen
/// ----------
/// Entry point of the app. Shows:
/// - Student ID input field
/// - Current session status card
/// - Check-in and Finish Class action buttons
/// - Session statistics

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _studentIdController = TextEditingController(text: 'STD001');

  CheckInRecord? _activeSession;
  bool _loading = true;
  int _totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final checkIns = await DatabaseService.instance.getAllCheckIns();
      setState(() => _totalSessions = checkIns.length);

      CheckInRecord? active;
      for (final ci in checkIns) {
        final co =
            await DatabaseService.instance.getCheckOutByCheckinId(ci.id!);
        if (co == null) {
          active = ci; // Found session without check-out → it's active
          break;
        }
      }
      setState(() => _activeSession = active);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Navigation ───────────────────────────────────────────────────

  String get _studentId =>
      _studentIdController.text.trim().isEmpty
          ? 'STD001'
          : _studentIdController.text.trim();

  Future<void> _goToCheckIn() async {
    final result = await Navigator.pushNamed(
      context,
      '/checkin',
      arguments: {'studentId': _studentId},
    );
    if (result == true) _loadStatus();
  }

  Future<void> _goToFinishClass() async {
    if (_activeSession?.id == null) return;
    final result = await Navigator.pushNamed(
      context,
      '/finish',
      arguments: {
        'studentId': _studentId,
        'checkinId': _activeSession!.id,
      },
    );
    if (result == true) _loadStatus();
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStudentIdField(),
                const SizedBox(height: 20),
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildStatsRow(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver AppBar with gradient ───────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: const Text(
          'Smart Check-in',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -50,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // App icon + subtitle
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Class Attendance & Reflection',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Student ID field ──────────────────────────────────────────────

  Widget _buildStudentIdField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _studentIdController,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Session status card ───────────────────────────────────────────

  Widget _buildStatusCard() {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final isCheckedIn = _activeSession != null;
    final statusColor =
        isCheckedIn ? AppTheme.warning : AppTheme.onSurfaceMuted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCheckedIn
                        ? Icons.pending_actions_rounded
                        : Icons.check_circle_outline_rounded,
                    color: statusColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status',
                      style: TextStyle(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCheckedIn ? 'Session In Progress' : 'No Active Session',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.onSurfaceMuted,
                  ),
                  onPressed: _loadStatus,
                ),
              ],
            ),

            // Active session details
            if (_activeSession != null) ...[
              const Divider(),
              _infoRow(Icons.person_outline, 'Student', _activeSession!.studentId),
              const SizedBox(height: 8),
              _infoRow(
                Icons.access_time_rounded,
                'Checked in',
                _formatDateTime(_activeSession!.checkinTime),
              ),
              const SizedBox(height: 8),
              _infoRow(
                Icons.qr_code_rounded,
                'QR Code',
                _activeSession!.qrCodeCheckin,
              ),
              const SizedBox(height: 8),
              _infoRow(
                Icons.location_on_outlined,
                'GPS',
                '${_activeSession!.checkinGpsLat.toStringAsFixed(5)}, '
                    '${_activeSession!.checkinGpsLng.toStringAsFixed(5)}',
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Press "Check-in to Class" to start a new session.',
                style: TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 8),
        Text(
          '$label:  ',
          style: const TextStyle(
            color: AppTheme.onSurfaceMuted,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final isCheckedIn = _activeSession != null;

    return Column(
      children: [
        // Check-in
        SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton.icon(
            onPressed: isCheckedIn ? null : _goToCheckIn,
            icon: const Icon(Icons.login_rounded, size: 22),
            label: const Text('Check-in to Class', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.surfaceVariant,
              disabledForegroundColor: AppTheme.onSurfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Finish Class
        SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton.icon(
            onPressed: isCheckedIn ? _goToFinishClass : null,
            icon: const Icon(Icons.logout_rounded, size: 22),
            label: const Text('Finish Class', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.black87,
              disabledBackgroundColor: AppTheme.surfaceVariant,
              disabledForegroundColor: AppTheme.onSurfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.calendar_today_rounded,
            value: _totalSessions.toString(),
            label: 'Total Sessions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: _activeSession != null
                ? Icons.radio_button_on_rounded
                : Icons.radio_button_off_rounded,
            value: _activeSession != null ? 'Active' : 'Idle',
            label: 'Session',
            iconColor:
                _activeSession != null ? AppTheme.warning : AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }
}
