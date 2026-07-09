import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 應急畫面:一鍵撥打預設聯絡人電話 + 輕微中暑自救指南。
/// 隱患上報(拍照+文字)可以之後接 image_picker 套件擴充,
/// 這裡先留一個文字回報的簡易版本。
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  // 依實際情況修改成朋友/工班的真實電話
  static const _contacts = [
    {'name': '工友 A', 'phone': '0912345678'},
    {'name': '領班', 'phone': '0987654321'},
    {'name': '119 緊急救護', 'phone': '119'},
  ];

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('緊急求助')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('一鍵撥打', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._contacts.map((c) => Card(
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.red),
                  title: Text(c['name']!),
                  subtitle: Text(c['phone']!),
                  onTap: () => _call(c['phone']!),
                ),
              )),
          const SizedBox(height: 24),
          const Text('輕微中暑自救指南', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '1. 立刻移動到陰涼、通風處平躺或坐下\n'
                '2. 解開衣領、鬆開束縛的衣物\n'
                '3. 用濕毛巾冷敷額頭、頸部、腋下\n'
                '4. 少量多次補充淡鹽水或運動飲料,不要牛飲\n'
                '5. 若意識模糊、持續嘔吐或超過 15 分鐘未改善,\n'
                '   立刻撥打 119 就醫',
                style: TextStyle(height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('設備隱患回報', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _HazardReportForm(),
        ],
      ),
    );
  }
}

class _HazardReportForm extends StatefulWidget {
  @override
  State<_HazardReportForm> createState() => _HazardReportFormState();
}

class _HazardReportFormState extends State<_HazardReportForm> {
  final _controller = TextEditingController();

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    // TODO: 之後可以接 image_picker 讓使用者附加照片,
    // 並用 http 套件把回報內容送到後端或訊息群組
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('隱患已記錄(示範版僅本機儲存,可擴充上傳功能)')),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '例如:三樓樓梯扶手鬆動',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('送出回報'),
            ),
          ],
        ),
      ),
    );
  }
}
