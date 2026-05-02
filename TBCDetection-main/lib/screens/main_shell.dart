import 'package:flutter/material.dart';

import '../services/forward_chaining_engine.dart';
import '../theme/app_theme.dart';
import 'admin_symptoms_screen.dart';
import 'result_screen.dart';
import 'tb_detection_screen.dart';
import 'tb_info_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  InferenceResult? _lastResult;
  final ValueNotifier<int> _reloadSymptomsTick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _reloadSymptomsTick.dispose();
    super.dispose();
  }

  void _onResult(InferenceResult result) {
    setState(() {
      _lastResult = result;
      _index = 2; // pindah ke tab Hasil
    });
  }

  Widget _body() {
    switch (_index) {
      case 0:
        return TbInfoScreen(
          onStartScreening: () => setState(() => _index = 1),
        );
      case 1:
        return TbDetectionScreen(
          reloadSignal: _reloadSymptomsTick,
          onResult: _onResult,
        );
      case 2:
        if (_lastResult != null) {
          return ResultScreen(
            result: _lastResult!,
            onRetry: () => setState(() => _index = 1),
          );
        }
        return _EmptyHasilState(
          onStart: () => setState(() => _index = 1),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 18, color: AppTheme.blueBright),
            SizedBox(width: 6),
            Text(
              'TBC Screening',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Admin — kelola gejala di Spreadsheet',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminSymptomsScreen(),
                ),
              );
              if (mounted) _reloadSymptomsTick.value++;
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _body(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Skrining',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _lastResult != null,
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: const Icon(Icons.assignment_rounded),
            label: 'Hasil',
          ),
        ],
      ),
    );
  }
}

// ── Empty state tab Hasil ──────────────────────────────────────────────────────

class _EmptyHasilState extends StatelessWidget {
  const _EmptyHasilState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada hasil skrining',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lakukan skrining gejala terlebih dahulu\nuntuk melihat hasil diagnosa.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Mulai Skrining'),
            ),
          ],
        ),
      ),
    );
  }
}
