import 'package:clashmi/screens/android_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows live VPN status and dashboard navigation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 857);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var tab = AndroidDashboardTab.dashboard;
    var mode = 1;
    var status = AndroidTunnelStatus.running;
    Widget dashboard() => MaterialApp(
      theme: ThemeData(useMaterial3: true, platform: TargetPlatform.android),
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: AndroidDashboard(
            labels: const AndroidDashboardLabels('zh', 'CN'),
            tab: tab,
            onTabChanged: (next) => setState(() => tab = next),
            tabContent: tab == AndroidDashboardTab.dashboard
                ? null
                : Center(child: Text(tab.name)),
            settingsLabel: '设置',
            status: status,
            statusLabel: status == AndroidTunnelStatus.running ? '运行中' : '已断开',
            toggleLabel: '连接',
            onToggle: () =>
                setState(() => status = AndroidTunnelStatus.stopped),
            traffic: ValueNotifier(
              const AndroidDashboardTraffic(
                uploadSpeed: 7600,
                downloadSpeed: 8000,
                connections: 12,
                history: [8, 8.2, 9, 11, 14, 15.5, 16],
              ),
            ),
            formatTraffic: (value) => '${(value / 1000).toStringAsFixed(1)} KB',
            uptime: ValueNotifier(const Duration(seconds: 2)),
            service: ValueNotifier('SHA → HKG · GOMAMI'),
            outboundModes: const ['规则', '全局', '直连'],
            selectedMode: mode,
            onModeChanged: (next) => setState(() => mode = next),
            appRouting: '全部应用',
            appRuleCount: 0,
            onAppRouting: () {},
            onCurrentService: () =>
                setState(() => tab = AndroidDashboardTab.nodes),
          ),
        ),
      ),
    );

    await tester.pumpWidget(dashboard());
    await tester.pumpAndSettle();

    expect(find.text('运行中 · 00:00:02'), findsOneWidget);
    expect(find.text('↑ 7.6 KB/s  ↓ 8.0 KB/s'), findsOneWidget);
    expect(find.text('SHA → HKG · GOMAMI'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.text('规则'));
    await tester.pumpAndSettle();
    expect(mode, 0);

    await tester.tap(find.text('服务'));
    await tester.pumpAndSettle();
    expect(find.text('services'), findsOneWidget);

    await tester.tap(find.text('仪表盘'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('连接'));
    await tester.pumpAndSettle();

    expect(find.text('已断开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
