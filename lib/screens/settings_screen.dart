// ============================================================
// screens/settings_screen.dart
// App settings: language, alerts, sensitivity, privacy
// ============================================================

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _cantonese = true;
  bool _voiceAlerts = true;
  bool _hapticAlerts = true;
  bool _microLearning = true;
  bool _anonymousContribute = false;
  double _sensitivity = 1.0;
  int _breakReminderMinutes = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定 / Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(_cantonese ? '語言 / Language' : 'Language'),
          _buildCard([
            SwitchListTile(
              title: Text(_cantonese ? '廣東話介面' : 'Cantonese Interface'),
              subtitle: Text(_cantonese ? '切換為廣東話/English' : 'Switch Cantonese/English'),
              value: _cantonese,
              onChanged: (v) => setState(() => _cantonese = v),
              activeColor: const Color(0xFF3498DB),
            ),
            SwitchListTile(
              title: Text(_cantonese ? '廣東話語音提示' : 'Cantonese Voice Alerts'),
              subtitle: Text(_cantonese ? '使用廣東話語音警報' : 'Voice alerts in Cantonese'),
              value: _cantonese,
              onChanged: (v) => setState(() => _cantonese = v),
              activeColor: const Color(0xFF3498DB),
            ),
          ]),

          _sectionHeader(_cantonese ? '警報設定' : 'Alert Settings'),
          _buildCard([
            SwitchListTile(
              title: Text(_cantonese ? '語音警報' : 'Voice Alerts'),
              value: _voiceAlerts,
              onChanged: (v) => setState(() => _voiceAlerts = v),
              activeColor: const Color(0xFF3498DB),
            ),
            SwitchListTile(
              title: Text(_cantonese ? '震動反饋' : 'Haptic Feedback'),
              value: _hapticAlerts,
              onChanged: (v) => setState(() => _hapticAlerts = v),
              activeColor: const Color(0xFF3498DB),
            ),
            SwitchListTile(
              title: Text(_cantonese ? '安全小貼士' : 'Safety Micro-Tips'),
              subtitle: Text(_cantonese ? '持續高風險時顯示' : 'Show on sustained high risk'),
              value: _microLearning,
              onChanged: (v) => setState(() => _microLearning = v),
              activeColor: const Color(0xFF3498DB),
            ),
          ]),

          _sectionHeader(_cantonese ? '監測靈敏度' : 'Detection Sensitivity'),
          _buildCard([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cantonese ? '角度靈敏度' : 'Angle Sensitivity',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Low', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _sensitivity,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          label: _sensitivity.toStringAsFixed(1) + 'x',
                          onChanged: (v) => setState(() => _sensitivity = v),
                          activeColor: const Color(0xFF3498DB),
                        ),
                      ),
                      const Text('High', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cantonese ? '休息提醒間隔：${_breakReminderMinutes}分鐘'
                               : 'Break Reminder: ${_breakReminderMinutes}min',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Slider(
                    value: _breakReminderMinutes.toDouble(),
                    min: 20,
                    max: 90,
                    divisions: 7,
                    label: '${_breakReminderMinutes}min',
                    onChanged: (v) =>
                        setState(() => _breakReminderMinutes = v.toInt()),
                    activeColor: const Color(0xFF27AE60),
                  ),
                ],
              ),
            ),
          ]),

          _sectionHeader(_cantonese ? '私隱設定' : 'Privacy'),
          _buildCard([
            SwitchListTile(
              title: Text(_cantonese ? '匿名貢獻數據' : 'Anonymous Data Contribution'),
              subtitle: Text(
                _cantonese
                    ? '匿名分享整體風險統計（不包含個人資料）'
                    : 'Share anonymised aggregate risk stats (no personal data)',
              ),
              value: _anonymousContribute,
              onChanged: (v) => setState(() => _anonymousContribute = v),
              activeColor: const Color(0xFF3498DB),
            ),
            ListTile(
              title: Text(
                _cantonese ? '清除所有數據' : 'Clear All Data',
                style: const TextStyle(color: Color(0xFFE74C3C)),
              ),
              leading: const Icon(Icons.delete_outline, color: Color(0xFFE74C3C)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF161B22),
                    title: Text(_cantonese ? '確認清除' : 'Confirm Clear'),
                    content: Text(
                      _cantonese ? '所有監測數據將被刪除。' : 'All monitoring data will be deleted.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_cantonese ? '取消' : 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          _cantonese ? '清除' : 'Clear',
                          style: const TextStyle(color: Color(0xFFE74C3C)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),

          _sectionHeader(_cantonese ? '關於' : 'About'),
          _buildCard([
            const ListTile(
              title: Text('ErgoGuard HK AI', style: TextStyle(color: Colors.white)),
              subtitle: Text('v1.0.0', style: TextStyle(color: Colors.white38)),
            ),
            ListTile(
              title: const Text('OSH References', style: TextStyle(color: Colors.white70)),
              subtitle: const Text(
                'Labour Dept · OSHC · Nordic Questionnaire',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              leading: const Icon(Icons.link, color: Color(0xFF3498DB)),
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF3498DB),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      child: Column(children: children),
    );
  }
}
