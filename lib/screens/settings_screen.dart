import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _soundService = SoundService();
  final _player = AudioPlayer();
  Map<String, String>? _currentSound;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await _soundService.getSavedCustomSound();
    setState(() => _currentSound = saved);
  }

  Future<void> _pickSound() async {
    setState(() => _loading = true);
    try {
      final picked = await _soundService.pickAndSaveCustomSound();
      if (picked != null) {
        await NotificationService.instance.setCustomSound(picked['uri']);
        setState(() => _currentSound = picked);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已設定通知鈴聲:${picked['name']}')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('未選擇音檔,或轉換失敗')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _preview() async {
    final localPath = _currentSound?['localPath'];
    if (localPath != null) {
      await _player.play(DeviceFileSource(localPath));
    }
  }

  Future<void> _resetSound() async {
    await _soundService.clearCustomSound();
    await NotificationService.instance.setCustomSound(null);
    setState(() => _currentSound = null);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已恢復系統預設鈴聲')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知鈴聲設定')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('目前通知鈴聲'),
                subtitle: Text(_currentSound?['name'] ?? '系統預設鈴聲'),
                trailing: _currentSound == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: _preview,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickSound,
              icon: const Icon(Icons.upload_file),
              label: Text(_loading ? '處理中…' : '從手機選擇音檔上傳'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _currentSound == null ? null : _resetSound,
              icon: const Icon(Icons.restore),
              label: const Text('恢復系統預設鈴聲'),
            ),
            const SizedBox(height: 24),
            Text(
              '支援 mp3 / wav / ogg / m4a 格式。\n'
              '選擇後,所有提醒(喝水、自測、休息、異常警告)都會使用這個鈴聲。\n'
              '需要 Android 原生設定才能生效,詳見專案 README。',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
