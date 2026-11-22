import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AndroidDashboardTab { dashboard, services, nodes, settings }

enum AndroidTunnelStatus { stopped, transitioning, running }

class AndroidDashboardLabels {
  const AndroidDashboardLabels(String language, [String? country])
    : _simplified = language == 'zh' && country != 'TW' && country != 'HK',
      _traditional = language == 'zh' && (country == 'TW' || country == 'HK');

  final bool _simplified;
  final bool _traditional;

  String _text(String en, String zh, String tw) => _simplified
      ? zh
      : _traditional
      ? tw
      : en;

  String get dashboard => _text('Dashboard', '仪表盘', '儀表板');
  String get services => _text('Services', '服务', '服務');
  String get nodes => _text('Nodes', '节点', '節點');
  String get running => _text('Running', '运行中', '運作中');
  String get speed => _text('Speed', '网速', '網速');
  String get outbound => _text('Outbound mode', '出站模式', '出站模式');
  String get currentService => _text('Current service', '当前服务', '目前服務');
  String get appRouting => _text('App routing', '应用分流', '應用程式分流');
  String get allApps => _text('All apps', '全部应用', '所有應用程式');
  String get traffic => _text('Traffic usage', '流量用量', '流量用量');
  String get connections => _text('Connections', '连接数', '連線數');
  String appRules(int count) => _text(
    count == 1 ? '1 app rule' : '$count app rules',
    '$count 条应用规则',
    '$count 條應用程式規則',
  );
}

class AndroidDashboardTraffic {
  const AndroidDashboardTraffic({
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.uploadTotal = 0,
    this.downloadTotal = 0,
    this.connections,
    this.history = const [],
  });

  final int uploadSpeed;
  final int downloadSpeed;
  final num uploadTotal;
  final num downloadTotal;
  final int? connections;
  final List<double> history;
}

class AndroidDashboard extends StatelessWidget {
  const AndroidDashboard({
    super.key,
    required this.labels,
    required this.tab,
    required this.onTabChanged,
    required this.settingsLabel,
    required this.status,
    required this.statusLabel,
    required this.toggleLabel,
    required this.onToggle,
    required this.traffic,
    required this.formatTraffic,
    required this.uptime,
    required this.service,
    required this.outboundModes,
    required this.selectedMode,
    required this.onModeChanged,
    required this.appRouting,
    required this.appRuleCount,
    required this.onAppRouting,
    required this.onCurrentService,
    this.onConnections,
    this.tabContent,
    this.hasBackgroundDecoration = false,
  });

  final AndroidDashboardLabels labels;
  final AndroidDashboardTab tab;
  final ValueChanged<AndroidDashboardTab> onTabChanged;
  final String settingsLabel;
  final AndroidTunnelStatus status;
  final String statusLabel;
  final String toggleLabel;
  final VoidCallback? onToggle;
  final ValueListenable<AndroidDashboardTraffic> traffic;
  final String Function(num) formatTraffic;
  final ValueListenable<Duration> uptime;
  final ValueListenable<String> service;
  final List<String> outboundModes;
  final int selectedMode;
  final ValueChanged<int>? onModeChanged;
  final String appRouting;
  final int appRuleCount;
  final VoidCallback onAppRouting;
  final VoidCallback onCurrentService;
  final VoidCallback? onConnections;
  final Widget? tabContent;
  final bool hasBackgroundDecoration;

  @override
  Widget build(BuildContext context) {
    final colors = _DashboardColors(Theme.of(context).colorScheme);
    return ColoredBox(
      color: hasBackgroundDecoration ? Colors.transparent : colors.background,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Expanded(child: tabContent ?? _buildDashboard(context, colors)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: _buildDock(context, colors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, _DashboardColors colors) {
    final theme = Theme.of(context);
    final running = status == AndroidTunnelStatus.running;
    final busy = status == AndroidTunnelStatus.transitioning;
    return SingleChildScrollView(
      key: const PageStorageKey('android-dashboard'),
      padding: const EdgeInsets.fromLTRB(18, 44, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels.dashboard,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w500,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ValueListenableBuilder<Duration>(
                        valueListenable: uptime,
                        builder: (context, elapsed, child) => Text(
                          running
                              ? '$statusLabel · ${_clock(elapsed)}'
                              : statusLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.muted,
                            height: 1.2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: running ? colors.green : colors.selected,
                  ),
                  alignment: Alignment.center,
                  child: busy
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.blue,
                          ),
                        )
                      : Icon(
                          running
                              ? Icons.check_rounded
                              : Icons.power_off_outlined,
                          color: running ? Colors.white : colors.muted,
                          size: 29,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          ValueListenableBuilder<AndroidDashboardTraffic>(
            valueListenable: traffic,
            builder: (context, data, child) => _DashboardCard(
              colors: colors,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 9),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _CardHeading(Icons.speed_rounded, labels.speed, colors),
                        Text(
                          '↑ ${formatTraffic(data.uploadSpeed)}/s  '
                          '↓ ${formatTraffic(data.downloadSpeed)}/s',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.muted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 123,
                    child: CustomPaint(
                      painter: _SpeedChart(data.history, colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final mode = _buildModeCard(colors);
              final apps = _buildAppRoutingCard(context, colors);
              final current = _buildServiceCard(context, colors);
              final usage = _buildTrafficCard(context, colors);
              final connections = _buildConnectionsCard(context, colors);
              const gap = SizedBox(height: 14);
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(16) > 22) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    mode,
                    gap,
                    current,
                    gap,
                    apps,
                    gap,
                    usage,
                    gap,
                    connections,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [mode, gap, apps],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [current, gap, usage, gap, connections],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(_DashboardColors colors) {
    return _DashboardCard(
      colors: colors,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PopupMenuButton<int>(
            enabled: onModeChanged != null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 112, maxWidth: 250),
            onSelected: onModeChanged,
            itemBuilder: (context) => [
              PopupMenuItem(value: 2, child: Text(outboundModes[2])),
            ],
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: _CardHeading(
                      Icons.alt_route_rounded,
                      labels.outbound,
                      colors,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.more_horiz, size: 19, color: colors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          _modeOption(colors, 0, Icons.list_alt_rounded),
          const SizedBox(height: 7),
          _modeOption(colors, 1, Icons.language_rounded),
          if (selectedMode == 2) ...[
            const SizedBox(height: 7),
            _modeOption(colors, 2, Icons.arrow_forward_rounded),
          ],
        ],
      ),
    );
  }

  Widget _modeOption(_DashboardColors colors, int index, IconData icon) {
    final selected = index == selectedMode;
    final enabled = onModeChanged != null;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !selected ? () => onModeChanged!(index) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _CardHeading(icon, outboundModes[index], colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppRoutingCard(BuildContext context, _DashboardColors colors) {
    return _DashboardCard(
      colors: colors,
      onTap: onAppRouting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(Icons.apps_rounded, labels.appRouting, colors),
          const SizedBox(height: 18),
          Text(
            appRouting,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: colors.ink),
          ),
          const SizedBox(height: 7),
          Text(
            labels.appRules(appRuleCount),
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, _DashboardColors colors) {
    return _DashboardCard(
      colors: colors,
      onTap: onCurrentService,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(Icons.hub_outlined, labels.currentService, colors),
          const SizedBox(height: 14),
          ValueListenableBuilder<String>(
            valueListenable: service,
            builder: (context, name, child) => Text(
              name.isEmpty ? '—' : name.replaceAll(' -> ', ' → '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colors.link, height: 1.32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficCard(BuildContext context, _DashboardColors colors) {
    return _DashboardCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(Icons.donut_large_rounded, labels.traffic, colors),
          const SizedBox(height: 15),
          ValueListenableBuilder<AndroidDashboardTraffic>(
            valueListenable: traffic,
            builder: (context, data, child) => Row(
              children: [
                SizedBox.square(
                  dimension: 48,
                  child: CustomPaint(
                    painter: _TrafficRing(
                      data.uploadTotal,
                      data.downloadTotal,
                      colors,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _usageLabel(
                        '↑ ${formatTraffic(data.uploadTotal)}',
                        colors.orange,
                        colors.ink,
                      ),
                      const SizedBox(height: 4),
                      _usageLabel(
                        '↓ ${formatTraffic(data.downloadTotal)}',
                        colors.blue,
                        colors.ink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageLabel(String text, Color dot, Color ink) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: dot),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: TextStyle(color: ink, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildConnectionsCard(BuildContext context, _DashboardColors colors) {
    return _DashboardCard(
      colors: colors,
      onTap: onConnections,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(Icons.account_tree_outlined, labels.connections, colors),
          const SizedBox(height: 14),
          ValueListenableBuilder<AndroidDashboardTraffic>(
            valueListenable: traffic,
            builder: (context, data, child) => Text(
              status == AndroidTunnelStatus.stopped
                  ? '0'
                  : data.connections?.toString() ?? '—',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDock(BuildContext context, _DashboardColors colors) {
    final dock = [
      (
        AndroidDashboardTab.dashboard,
        Icons.dashboard_rounded,
        labels.dashboard,
      ),
      (AndroidDashboardTab.services, Icons.public_rounded, labels.services),
      (AndroidDashboardTab.nodes, Icons.hub_outlined, labels.nodes),
      (AndroidDashboardTab.settings, Icons.settings_outlined, settingsLabel),
    ];
    return Row(
      children: [
        Expanded(
          child: Material(
            color: colors.dock,
            elevation: 5,
            shadowColor: Colors.black.withValues(alpha: .22),
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  for (final (destination, icon, label) in dock)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: tab == destination,
                        child: Material(
                          color: tab == destination
                              ? colors.selected
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => onTabChanged(destination),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 9,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 23, color: colors.muted),
                                  const SizedBox(height: 4),
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: colors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox.square(
          dimension: 68,
          child: FloatingActionButton(
            heroTag: null,
            tooltip: toggleLabel,
            elevation: 5,
            backgroundColor: colors.button,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: onToggle,
            child: status == AndroidTunnelStatus.transitioning
                ? const SizedBox.square(
                    dimension: 23,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(
                    status == AndroidTunnelStatus.running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 34,
                  ),
          ),
        ),
      ],
    );
  }

  static String _clock(Duration elapsed) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(elapsed.inHours)}:${two(elapsed.inMinutes.remainder(60))}:'
        '${two(elapsed.inSeconds.remainder(60))}';
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.onTap,
  });

  final _DashboardColors colors;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(21),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading(this.icon, this.title, this.colors);

  final IconData icon;
  final String title;
  final _DashboardColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colors.muted),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: colors.ink),
          ),
        ),
      ],
    );
  }
}

class _DashboardColors {
  _DashboardColors(ColorScheme scheme)
    : background = scheme.brightness == Brightness.dark
          ? scheme.surface
          : const Color(0xFFF6F5FB),
      card = scheme.brightness == Brightness.dark
          ? scheme.surfaceContainer
          : const Color(0xFFEBECF8),
      dock = scheme.brightness == Brightness.dark
          ? scheme.surfaceContainerHigh
          : const Color(0xFFE6E7F3),
      selected = scheme.brightness == Brightness.dark
          ? scheme.secondaryContainer
          : const Color(0xFFDCE0FA),
      ink = scheme.brightness == Brightness.dark
          ? scheme.onSurface
          : const Color(0xFF1B1B23),
      muted = scheme.brightness == Brightness.dark
          ? scheme.onSurfaceVariant
          : const Color(0xFF464654),
      blue = scheme.brightness == Brightness.dark
          ? scheme.primary
          : const Color(0xFF0B50B8),
      link = scheme.brightness == Brightness.dark
          ? scheme.primary
          : const Color(0xFF185895),
      orange = scheme.brightness == Brightness.dark
          ? const Color(0xFFFFB785)
          : const Color(0xFF9D430D);

  final Color background;
  final Color card;
  final Color dock;
  final Color selected;
  final Color ink;
  final Color muted;
  final Color blue;
  final Color link;
  final Color orange;
  final Color button = const Color(0xFF074AB7);
  final Color green = const Color(0xFF158A44);
}

class _SpeedChart extends CustomPainter {
  const _SpeedChart(this.history, this.color);

  final List<double> history;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = history.fold(1.0, (peak, rate) => math.max(peak, rate));
    final samples = history.length < 2
        ? [
            history.isEmpty ? 0.0 : history.first,
            history.isEmpty ? 0.0 : history.first,
          ]
        : history;
    const top = 6.0;
    final baseline = size.height - 1.5;
    final step = size.width / (samples.length - 1);
    double ordinate(double sample) =>
        baseline - (baseline - top) * sample / peak;
    final stroke = Path()..moveTo(0, ordinate(samples.first));
    for (int index = 1; index < samples.length; index++) {
      final x = index * step;
      final previous = ordinate(samples[index - 1]);
      final y = ordinate(samples[index]);
      final before = ordinate(samples[math.max(0, index - 2)]);
      final after = ordinate(samples[math.min(samples.length - 1, index + 1)]);
      final low = math.min(previous, y);
      final high = math.max(previous, y);
      stroke.cubicTo(
        x - 2 * step / 3,
        (previous + (y - before) / 6).clamp(low, high).toDouble(),
        x - step / 3,
        (y - (after - previous) / 6).clamp(low, high).toDouble(),
        x,
        y,
      );
    }
    final fill = Path.from(stroke)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .34), color.withValues(alpha: .05)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      stroke,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_SpeedChart oldDelegate) =>
      oldDelegate.history != history || oldDelegate.color != color;
}

class _TrafficRing extends CustomPainter {
  const _TrafficRing(this.upload, this.download, this.colors);

  final num upload;
  final num download;
  final _DashboardColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 6.5;
    const start = -math.pi / 2;
    const full = math.pi * 2;
    final rect = (Offset.zero & size).deflate(width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final total = upload + download;
    if (total <= 0) {
      canvas.drawOval(rect, paint..color = colors.selected);
      return;
    }
    final uploaded = full * upload / total;
    canvas.drawArc(rect, start, uploaded, false, paint..color = colors.orange);
    canvas.drawArc(
      rect,
      start + uploaded,
      full - uploaded,
      false,
      paint..color = colors.blue,
    );
  }

  @override
  bool shouldRepaint(_TrafficRing oldDelegate) =>
      oldDelegate.upload != upload ||
      oldDelegate.download != download ||
      oldDelegate.colors.orange != colors.orange ||
      oldDelegate.colors.blue != colors.blue ||
      oldDelegate.colors.selected != colors.selected;
}
