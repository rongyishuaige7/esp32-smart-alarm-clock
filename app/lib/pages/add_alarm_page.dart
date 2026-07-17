import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';

class AddAlarmPage extends StatefulWidget {
  const AddAlarmPage({super.key});

  @override
  State<AddAlarmPage> createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends State<AddAlarmPage>
    with SingleTickerProviderStateMixin {
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _submitting = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: const Color(0xFF1A2D42),
            hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF0D1B2A)),
            hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.white
                    : const Color(0xFF90CAF9)),
            dialBackgroundColor: const Color(0xFF0D1B2A),
            dialHandColor: const Color(0xFF1976D2),
            dialTextColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.white
                    : const Color(0xFFBBDEFB)),
            entryModeIconColor: const Color(0xFF42A5F5),
            dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF0D1B2A)),
            dayPeriodTextColor: const Color(0xFF90CAF9),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: const Color(0xFF42A5F5),
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: const Color(0xFF546E7A),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final provider = context.read<AlarmProvider>();
    await _scaleCtrl.reverse();
    await _scaleCtrl.forward();

    setState(() => _submitting = true);
    final ok = await provider.addAlarm(
      _selectedTime.hour,
      _selectedTime.minute,
      true,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 18),
              const SizedBox(width: 8),
              Text(
                '闹钟已设置为 ${_selectedTime.hour.toString().padLeft(2, "0")}:'
                '${_selectedTime.minute.toString().padLeft(2, "0")}',
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.lastError ?? '添加失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _selectedTime.hour.toString().padLeft(2, '0');
    final m = _selectedTime.minute.toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加闹钟'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── 时间展示卡 ──
              GestureDetector(
                onTap: _submitting ? null : _selectTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2550), Color(0xFF0D47A1), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '闹钟时间',
                        style: TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            h,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 80,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 4,
                              height: 1.0,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              ':',
                              style: TextStyle(
                                color: Color(0xFF64B5F6),
                                fontSize: 60,
                                fontWeight: FontWeight.w200,
                                height: 1.0,
                              ),
                            ),
                          ),
                          Text(
                            m,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 80,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 4,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app,
                                size: 14, color: Color(0xFFBBDEFB)),
                            SizedBox(width: 6),
                            Text(
                              '点击修改时间',
                              style: TextStyle(
                                color: Color(0xFFBBDEFB),
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── 选择时间按钮 ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF42A5F5),
                    side: const BorderSide(color: Color(0xFF1E4070), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submitting ? null : _selectTime,
                  icon: const Icon(Icons.access_time_rounded, size: 20),
                  label: const Text(
                    '选择时间',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const Spacer(),

              // ── 保存按钮 ──
              ScaleTransition(
                scale: _scaleAnim,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm_add, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '保存闹钟',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
