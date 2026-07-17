import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<AlarmProvider>();
      await p.ensurePrefsLoaded();
      await p.loadAlarms();
      await p.refreshDashboard();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        context.read<AlarmProvider>().refreshDashboard();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _showBaseUrlDialog() async {
    final provider = context.read<AlarmProvider>();
    final controller = TextEditingController(text: provider.baseUrl);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Color(0xFF42A5F5), size: 22),
            SizedBox(width: 8),
            Text('设备地址', style: TextStyle(color: Color(0xFFE3F2FD))),
          ],
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFFE3F2FD)),
          decoration: InputDecoration(
            labelText: 'Base URL',
            hintText: 'http://设备实际 IP，例如 192.168.x.x',
            hintStyle: const TextStyle(color: Color(0xFF546E7A)),
            labelStyle: const TextStyle(color: Color(0xFF90CAF9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF0D1B2A),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF90CAF9))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await provider.setBaseUrl(controller.text);
      await provider.loadAlarms();
      await provider.refreshDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已设为 ${provider.baseUrl}')),
      );
    }
  }

  Future<void> _onStopAlarm() async {
    final provider = context.read<AlarmProvider>();
    final ok = await provider.stopRemoteAlarm();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '已发送停止指令' : (provider.lastError ?? '停止失败')),
      ),
    );
  }

  static String _fmtNum(dynamic v) {
    if (v == null) return '--';
    if (v is num) return v.toStringAsFixed(1);
    final d = double.tryParse(v.toString());
    return d != null ? d.toStringAsFixed(1) : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 智能闹钟'),
        centerTitle: true,
        actions: [
          Consumer<AlarmProvider>(
            builder: (context, p, _) {
              final active = p.deviceStatus?['alarm_active'] == true;
              return IconButton(
                tooltip: '停止闹钟',
                icon: Icon(
                  Icons.alarm_off,
                  color: active ? const Color(0xFFFF7043) : const Color(0xFF90CAF9),
                ),
                onPressed: _onStopAlarm,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设备地址',
            onPressed: _showBaseUrlDialog,
          ),
        ],
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, provider, _) {
          final st = provider.deviceStatus;
          final tm = provider.deviceTime;

          final hourStr = (tm?['hour'] ?? 0).toString().padLeft(2, '0');
          final minStr = (tm?['minute'] ?? 0).toString().padLeft(2, '0');
          final secStr = (tm?['second'] ?? 0).toString().padLeft(2, '0');
          final dateStr = tm == null ? '' : '${tm['date'] ?? ''}';

          final temp = _fmtNum(st?['temp']);
          final hum = _fmtNum(st?['humidity']);
          final motion = st == null ? null : (st['motion'] == true);
          final alarmActive = st == null ? false : (st['alarm_active'] == true);

          return RefreshIndicator(
            color: const Color(0xFF42A5F5),
            backgroundColor: const Color(0xFF1A2D42),
            onRefresh: () async {
              await provider.loadAlarms();
              await provider.refreshDashboard();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                _ClockCard(
                  hourStr: tm == null ? '--' : hourStr,
                  minStr: tm == null ? '--' : minStr,
                  secStr: tm == null ? '--' : secStr,
                  dateStr: dateStr,
                  pulse: _pulse,
                ),
                const SizedBox(height: 16),
                _EnvRow(temp: temp, hum: hum),
                const SizedBox(height: 12),
                _StateRow(
                  motion: motion,
                  alarmActive: alarmActive,
                  onStopAlarm: _onStopAlarm,
                ),
                const SizedBox(height: 16),
                _DeviceUrlBar(url: provider.baseUrl),
                if (provider.lastError != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBar(message: provider.lastError!),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'list',
            onPressed: () => Navigator.pushNamed(context, '/alarms'),
            icon: const Icon(Icons.alarm),
            label: const Text('闹钟列表'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => Navigator.pushNamed(context, '/add'),
            icon: const Icon(Icons.add),
            label: const Text('添加闹钟'),
          ),
        ],
      ),
    );
  }
}

// ── 时钟卡片 ─────────────────────────────────────────────────

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.hourStr,
    required this.minStr,
    required this.secStr,
    required this.dateStr,
    required this.pulse,
  });

  final String hourStr;
  final String minStr;
  final String secStr;
  final String dateStr;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (ctx, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2550), Color(0xFF0D47A1), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0xFF1565C0).withValues(alpha: 0.2),
                  const Color(0xFF1565C0).withValues(alpha: 0.5),
                  pulse.value,
                )!,
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          child: child,
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF42A5F5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '设备返回的时间',
                style: TextStyle(
                  color: Color(0xFF90CAF9),
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF42A5F5),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hourStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                  height: 1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                minStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                secStr,
                style: const TextStyle(
                  color: Color(0xFF90CAF9),
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dateStr,
                style: const TextStyle(
                  color: Color(0xFFBBDEFB),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 温湿度行 ─────────────────────────────────────────────────

class _EnvRow extends StatelessWidget {
  const _EnvRow({required this.temp, required this.hum});
  final String temp;
  final String hum;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EnvCard(
            icon: Icons.thermostat_rounded,
            iconColor: const Color(0xFFEF5350),
            gradientColors: const [Color(0xFF3A1212), Color(0xFF200A0A)],
            borderColor: const Color(0xFF6D2121),
            label: '温度',
            value: '$temp °C',
            valueColor: const Color(0xFFFF8A80),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _EnvCard(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF42A5F5),
            gradientColors: const [Color(0xFF0D2744), Color(0xFF071525)],
            borderColor: const Color(0xFF1E4070),
            label: '湿度',
            value: '$hum %',
            valueColor: const Color(0xFF82C8FF),
          ),
        ),
      ],
    );
  }
}

class _EnvCard extends StatelessWidget {
  const _EnvCard({
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.borderColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final Color borderColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 感应 + 闹钟状态行 ────────────────────────────────────────

class _StateRow extends StatelessWidget {
  const _StateRow({
    required this.motion,
    required this.alarmActive,
    required this.onStopAlarm,
  });

  final bool? motion;
  final bool alarmActive;
  final VoidCallback onStopAlarm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StateCard(
            icon: motion == true
                ? Icons.person_rounded
                : Icons.person_off_rounded,
            iconColor: motion == true
                ? const Color(0xFF66BB6A)
                : const Color(0xFF546E7A),
            label: '人体感应',
            value: motion == null ? '--' : (motion! ? '检测到人体' : '无人'),
            active: motion == true,
            activeColor: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: alarmActive ? onStopAlarm : null,
            child: _StateCard(
              icon: alarmActive ? Icons.alarm_rounded : Icons.alarm_off_rounded,
              iconColor: alarmActive
                  ? const Color(0xFFEF5350)
                  : const Color(0xFF546E7A),
              label: alarmActive ? '点击停止' : '闹钟',
              value: alarmActive ? '响铃中' : '静默',
              active: alarmActive,
              activeColor: const Color(0xFFC62828),
            ),
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.active,
    required this.activeColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withValues(alpha: 0.18)
            : const Color(0xFF101C2A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? activeColor.withValues(alpha: 0.7) : const Color(0xFF1E3A5F),
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF546E7A),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: active ? iconColor : const Color(0xFFCFD8DC),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 底部工具栏组件 ────────────────────────────────────────────

class _DeviceUrlBar extends StatelessWidget {
  const _DeviceUrlBar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.router_outlined, size: 14, color: Color(0xFF546E7A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(color: Color(0xFF546E7A), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF4E1B1B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB71C1C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF9A9A), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - t) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = math.min(size.width, size.height) / 2 * (0.5 + t * 0.5);
    canvas.drawCircle(size.center(Offset.zero), r, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}
