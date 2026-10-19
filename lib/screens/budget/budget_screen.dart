import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/budget_model.dart';
import '../../services/budget_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/peso.dart';

const _periods = ['Daily', 'Weekly', 'Monthly'];

String _friendlyError(Object? error) {
  final text = '$error';
  if (text.contains('permission-denied')) {
    return 'Firestore blocked this request. Check that your security rules '
        'allow users/{uid}/...';
  }
  if (text.contains('unavailable') || text.contains('network')) {
    return 'Could not reach Firestore. Check your internet connection.';
  }
  return 'Something went wrong: $text';
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _service = BudgetService();

  late Stream<BudgetModel> _budgetStream = _service.streamUserBudget();
  late Stream<PeriodSpending> _spendingStream = _service.streamSpending();

  // Period the student picked on this screen (null = use the saved one)
  String? _pickedPeriod;

  void _reload() {
    setState(() {
      _budgetStream = _service.streamUserBudget();
      _spendingStream = _service.streamSpending();
    });
  }

  double _limitFor(BudgetModel budget, String period) {
    switch (period) {
      case 'Daily':
        return budget.dailyBudget;
      case 'Weekly':
        return budget.weeklyBudget;
      default:
        return budget.monthlyBudget;
    }
  }

  Future<void> _pickPeriod(String period) async {
    setState(() => _pickedPeriod = period);
    try {
      await _service.updateSelectedPeriod(period);
    } catch (_) {
      // Not critical: the choice still works for this session.
    }
  }

  Future<void> _openLimitsSheet(BudgetModel current) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LimitsSheet(
        initial: current,
        onSave: (daily, weekly, monthly) => _service.saveBudget(
          dailyBudget: daily,
          weeklyBudget: weekly,
          monthlyBudget: monthly,
          selectedPeriod: _pickedPeriod ?? current.selectedPeriod,
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limits updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BudgetModel>(
      stream: _budgetStream,
      builder: (context, budgetSnap) {
        if (budgetSnap.hasError) {
          return _ErrorView(
            message: _friendlyError(budgetSnap.error),
            onRetry: _reload,
          );
        }
        if (!budgetSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final budget = budgetSnap.data!;
        final period = _pickedPeriod ?? budget.selectedPeriod;

        return StreamBuilder<PeriodSpending>(
          stream: _spendingStream,
          builder: (context, spendSnap) {
            final spending = spendSnap.data ?? PeriodSpending.zero;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textSecondary,
                          selectedBackgroundColor: AppColors.primary,
                          selectedForegroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        segments: [
                          for (final p in _periods)
                            ButtonSegment<String>(value: p, label: Text(p)),
                        ],
                        selected: {period},
                        onSelectionChanged: (set) => _pickPeriod(set.first),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SummaryCard(
                      period: period,
                      limit: _limitFor(budget, period),
                      spent: spending.forPeriod(period),
                      onSetLimits: () => _openLimitsSheet(budget),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Your limits',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _openLimitsSheet(budget),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Edit limits'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final p in _periods)
                      _LimitRow(
                        period: p,
                        limit: _limitFor(budget, p),
                        spent: spending.forPeriod(p),
                        highlighted: p == period,
                        onTap: () => _openLimitsSheet(budget),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card with a progress ring
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.period,
    required this.limit,
    required this.spent,
    required this.onSetLimits,
  });

  final String period;
  final double limit;
  final double spent;
  final VoidCallback onSetLimits;

  int _daysLeft() {
    final now = DateTime.now();
    switch (period) {
      case 'Weekly':
        return 8 - now.weekday; // Mon=7 days left ... Sun=1
      case 'Monthly':
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        return lastDay - now.day + 1;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLimit = limit > 0;
    final remaining = limit - spent;
    final ratio = hasLimit ? spent / limit : 0.0;
    final over = hasLimit && remaining < 0;

    final Color accent;
    final String status;
    if (!hasLimit) {
      accent = AppColors.textMuted;
      status = 'No limit set';
    } else if (over) {
      accent = AppColors.danger;
      status = 'Over budget';
    } else if (ratio >= 0.8) {
      accent = AppColors.warning;
      status = 'Almost at your limit';
    } else {
      accent = AppColors.success;
      status = 'On track';
    }

    String? paceHint;
    if (hasLimit && !over && period != 'Daily') {
      final perDay = remaining / _daysLeft();
      final unit = period == 'Weekly' ? 'week' : 'month';
      paceHint = 'About ${peso(perDay)} a day to last the rest of the $unit';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                painter: _RingPainter(
                  progress: value,
                  color: accent,
                  track: AppColors.surfaceHigh,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        over ? 'Over by' : 'Left',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLimit ? peso(remaining.abs()) : '—',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: over ? AppColors.danger : AppColors.textPrimary,
                        ),
                      ),
                      if (hasLimit)
                        Text(
                          '${(ratio * 100).round()}% used',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Stat(label: '$period limit', value: peso(limit)),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _Stat(label: 'Spent', value: peso(spent)),
              ),
            ],
          ),
          if (paceHint != null) ...[
            const SizedBox(height: 14),
            Text(
              paceHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (!hasLimit) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onSetLimits,
              child: const Text('Set your limits'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

// ---------------------------------------------------------------------------
// One row per period in the "Your limits" list
// ---------------------------------------------------------------------------

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.period,
    required this.limit,
    required this.spent,
    required this.highlighted,
    required this.onTap,
  });

  final String period;
  final double limit;
  final double spent;
  final bool highlighted;
  final VoidCallback onTap;

  IconData get _icon {
    switch (period) {
      case 'Daily':
        return Icons.wb_sunny_outlined;
      case 'Weekly':
        return Icons.view_week_outlined;
      default:
        return Icons.calendar_month_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final over = limit > 0 && spent > limit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlighted ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(_icon, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      period,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      limit > 0 ? peso(limit) : 'Not set',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: limit > 0
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (limit > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        over ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${peso(spent)} spent',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet for editing the three limits
// ---------------------------------------------------------------------------

class _LimitsSheet extends StatefulWidget {
  const _LimitsSheet({required this.initial, required this.onSave});

  final BudgetModel initial;
  final Future<void> Function(double daily, double weekly, double monthly)
      onSave;

  @override
  State<_LimitsSheet> createState() => _LimitsSheetState();
}

class _LimitsSheetState extends State<_LimitsSheet> {
  late final _daily =
      TextEditingController(text: plainAmount(widget.initial.dailyBudget));
  late final _weekly =
      TextEditingController(text: plainAmount(widget.initial.weeklyBudget));
  late final _monthly =
      TextEditingController(text: plainAmount(widget.initial.monthlyBudget));

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _daily.dispose();
    _weekly.dispose();
    _monthly.dispose();
    super.dispose();
  }

  // Empty box counts as 0; text that is not a number returns null.
  double? _read(TextEditingController controller) {
    if (controller.text.trim().isEmpty) return 0;
    return parseAmount(controller.text);
  }

  void _fillFromDaily() {
    final daily = _read(_daily);
    if (daily == null || daily <= 0) {
      setState(() => _error = 'Type a daily amount first.');
      return;
    }
    setState(() {
      _error = null;
      _weekly.text = plainAmount(daily * 7);
      _monthly.text = plainAmount(daily * 30);
    });
  }

  Future<void> _save() async {
    final daily = _read(_daily);
    final weekly = _read(_weekly);
    final monthly = _read(_monthly);

    if (daily == null || weekly == null || monthly == null) {
      setState(() => _error = 'Use numbers only, for example 150 or 150.50');
      return;
    }
    if (daily + weekly + monthly <= 0) {
      setState(() => _error = 'Enter at least one limit.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(daily, weekly, monthly);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _friendlyError(e);
        });
      }
    }
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, prefixText: '₱ '),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Spending limits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'How much can you spend in each period?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _field(_daily, 'Per day'),
            const SizedBox(height: 12),
            _field(_weekly, 'Per week'),
            const SizedBox(height: 12),
            _field(_monthly, 'Per month'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _saving ? null : _fillFromDaily,
                child: const Text('Fill week and month from daily (×7, ×30)'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save limits'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
