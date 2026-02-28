// ============================================================
// screens/home_screen.dart
// Main home screen with sector selection + shift history
// ============================================================

import 'package:flutter/material.dart';
import '../models/posture_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkerSector _selectedSector = WorkerSector.construction;
  bool _cantonese = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF1A3A5C)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Language toggle
                _buildLanguageToggle(),
                const SizedBox(height: 24),

                // Sector Selection
                _buildSectorSelection(),
                const SizedBox(height: 24),

                // Start Monitoring Button
                _buildStartButton(),
                const SizedBox(height: 24),

                // Quick Stats (mock)
                _buildQuickStats(),
                const SizedBox(height: 20),

                // OSHC Info card
                _buildOshcCard(),
                const SizedBox(height: 20),

                // Navigation Row
                _buildNavRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5276),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ErgoGuard HK AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _cantonese ? '個人人體工學守護者' : 'Personal Ergonomic Guardian',
                  style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFF27AE60), size: 16),
              const SizedBox(width: 6),
              Text(
                _cantonese
                    ? '全程離線 · 私隱保護 · 免費使用'
                    : 'Fully Offline · Privacy First · Free',
                style: const TextStyle(color: Color(0xFF27AE60), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('EN', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(width: 8),
        Switch(
          value: _cantonese,
          onChanged: (v) => setState(() => _cantonese = v),
          activeColor: const Color(0xFF1A5276),
        ),
        const SizedBox(width: 4),
        const Text('粵語', style: TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildSectorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _cantonese ? '選擇工作範疇' : 'Select Your Sector',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sectorCard(WorkerSector.construction)),
            const SizedBox(width: 12),
            Expanded(child: _sectorCard(WorkerSector.catering)),
          ],
        ),
      ],
    );
  }

  Widget _sectorCard(WorkerSector sector) {
    final isSelected = _selectedSector == sector;
    final isConstruction = sector == WorkerSector.construction;

    return GestureDetector(
      onTap: () => setState(() => _selectedSector = sector),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isConstruction ? const Color(0xFF1A5276) : const Color(0xFF6C3483))
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isConstruction ? const Color(0xFF3498DB) : const Color(0xFF9B59B6))
                : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: (isConstruction ? const Color(0xFF1A5276) : const Color(0xFF6C3483))
                      .withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                )]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              isConstruction ? Icons.construction : Icons.restaurant,
              color: isSelected ? Colors.white : Colors.white54,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              isConstruction
                  ? (_cantonese ? '建造業' : 'Construction')
                  : (_cantonese ? '飲食業' : 'Catering'),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isConstruction
                  ? (_cantonese ? 'REBA評分' : 'REBA Scoring')
                  : (_cantonese ? 'RULA/站立分析' : 'RULA/Standing'),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/monitor',
            arguments: {
              'sector': _selectedSector,
              'cantonese': _cantonese,
            },
          );
        },
        icon: const Icon(Icons.play_arrow, size: 28),
        label: Text(
          _cantonese ? '開始監測' : 'Start Monitoring',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: const Color(0xFF27AE60).withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _cantonese ? '今日統計' : "Today's Stats",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(
              _cantonese ? '已監測時間' : 'Monitored',
              '0h 0m',
              Icons.timer_outlined,
              const Color(0xFF3498DB),
            ),
            const SizedBox(width: 12),
            _statCard(
              _cantonese ? '高風險姿勢' : 'High Risk',
              '0%',
              Icons.warning_amber_outlined,
              const Color(0xFFE74C3C),
            ),
            const SizedBox(width: 12),
            _statCard(
              _cantonese ? '休息次數' : 'Breaks Taken',
              '0',
              Icons.self_improvement,
              const Color(0xFF27AE60),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOshcCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3498DB).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF3498DB), size: 18),
              const SizedBox(width: 8),
              Text(
                _cantonese ? '職安健資訊' : 'OSH Information',
                style: const TextStyle(
                  color: Color(0xFF3498DB),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cantonese
                ? '本應用根據勞工處《站立工作》及《體力處理作業》指引，以及職業安全健康局行業資源設計。'
                : 'This app is aligned with Labour Dept guidelines on Standing Work and Manual Handling, and OSHC industry resources.',
            style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow() {
    return Row(
      children: [
        Expanded(
          child: _navButton(
            icon: Icons.bar_chart,
            label: _cantonese ? '報告' : 'Report',
            route: '/report',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _navButton(
            icon: Icons.settings,
            label: _cantonese ? '設定' : 'Settings',
            route: '/settings',
          ),
        ),
      ],
    );
  }

  Widget _navButton({required IconData icon, required String label, required String route}) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
