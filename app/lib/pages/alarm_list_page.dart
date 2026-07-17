import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';

class AlarmListPage extends StatefulWidget {
  const AlarmListPage({super.key});

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlarmProvider>().loadAlarms();
    });
  }

  Future<void> _stopAlarm() async {
    final provider = context.read<AlarmProvider>();
    final ok = await provider.stopRemoteAlarm();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '已发送停止指令' : (provider.lastError ?? '失败')),
      ),
    );
  }

  Future<void> _toggleEnabled(Alarm alarm, bool value) async {
    final provider = context.read<AlarmProvider>();
    final updated = alarm.copyWith(enabled: value);
    final ok = await provider.updateAlarm(updated);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.lastError ?? '更新失败')),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext ctx) async {
    final result = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2D42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFEF5350), size: 22),
            SizedBox(width: 8),
            Text('删除闹钟', style: TextStyle(color: Color(0xFFE3F2FD))),
          ],
        ),
        content: const Text(
          '确认删除这个闹钟吗？',
          style: TextStyle(color: Color(0xFF90CAF9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF90CAF9))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('闹钟列表'),
        centerTitle: true,
        actions: [
          Consumer<AlarmProvider>(
            builder: (context, p, child) {
              final active = p.deviceStatus?['alarm_active'] == true;
              return IconButton(
                icon: Icon(
                  Icons.alarm_off,
                  color: active ? const Color(0xFFFF7043) : const Color(0xFF90CAF9),
                ),
                tooltip: '停止响铃',
                onPressed: _stopAlarm,
              );
            },
          ),
        ],
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
            );
          }

          // 有错误且列表为空，说明是网络/请求失败，不是真的没闹钟
          if (provider.alarms.isEmpty && provider.lastError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 56, color: Color(0xFF546E7A)),
                    const SizedBox(height: 20),
                    const Text(
                      '无法获取闹钟列表',
                      style: TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.lastError!,
                      style: const TextStyle(
                          color: Color(0xFF546E7A), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => provider.loadAlarms(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('重新加载'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.alarms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A2D42), Color(0xFF0D1B2A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(45),
                      border: Border.all(color: const Color(0xFF1E3A5F)),
                    ),
                    child: const Icon(Icons.alarm_add,
                        size: 44, color: Color(0xFF42A5F5)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '暂无闹钟',
                    style: TextStyle(
                      color: Color(0xFF546E7A),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '添加一个来叫醒自己吧',
                    style: TextStyle(color: Color(0xFF37474F), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/add')
                        .then((_) => provider.loadAlarms()),
                    icon: const Icon(Icons.add),
                    label: const Text('添加闹钟'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF42A5F5),
            backgroundColor: const Color(0xFF1A2D42),
            onRefresh: () => provider.loadAlarms(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.alarms.length,
              itemBuilder: (context, index) {
                final alarm = provider.alarms[index];
                return _AlarmCard(
                  alarm: alarm,
                  onToggle: (v) => _toggleEnabled(alarm, v),
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context);
                    if (!confirmed) return;
                    if (!context.mounted) return;
                    final ok = await context
                        .read<AlarmProvider>()
                        .deleteAlarm(alarm.id);
                    if (!context.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.lastError ?? '删除失败'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add');
          if (!context.mounted) return;
          await context.read<AlarmProvider>().loadAlarms();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: alarm.enabled
              ? const LinearGradient(
                  colors: [Color(0xFF1A2D42), Color(0xFF152538)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF0F1A26), Color(0xFF0A1320)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: alarm.enabled
                ? const Color(0xFF1E4070)
                : const Color(0xFF131F2E),
            width: 1.5,
          ),
          boxShadow: alarm.enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // 图标容器
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: alarm.enabled
                      ? const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: alarm.enabled ? null : const Color(0xFF1A2535),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: alarm.enabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.alarm_rounded,
                  size: 26,
                  color: alarm.enabled
                      ? Colors.white
                      : const Color(0xFF37474F),
                ),
              ),
              const SizedBox(width: 14),
              // 时间和状态
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.timeString,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 3,
                        color: alarm.enabled
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFF455A64),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: alarm.enabled
                                ? const Color(0xFF42A5F5)
                                : const Color(0xFF37474F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          alarm.enabled ? '已启用' : '已停用',
                          style: TextStyle(
                            fontSize: 12,
                            color: alarm.enabled
                                ? const Color(0xFF64B5F6)
                                : const Color(0xFF455A64),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 开关
              Switch(
                value: alarm.enabled,
                onChanged: onToggle,
              ),
              // 删除按钮
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E1B1B).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: const Color(0xFFEF9A9A),
                  tooltip: '删除',
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
