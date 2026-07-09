import 'dart:io';
import 'package:flutter/material.dart';
import '../services/customization_service.dart';
import '../models/ui_customization.dart';
import '../widgets/pattern_background.dart';
import '../widgets/app_scaled_button.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({super.key});

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  final _service = CustomizationService.instance;

  static const _colorSwatches = [
    Color(0xFFF5F5F5),
    Color(0xFFFFFFFF),
    Color(0xFFE0F2F1),
    Color(0xFFFFF3E0),
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
    Color(0xFFECEFF1),
    Color(0xFF263238),
  ];

  static const _patterns = ['none', 'dots', 'stripes', 'grid'];
  static const _patternLabels = {
    'none': '無圖案',
    'dots': '點點',
    'stripes': '斜紋',
    'grid': '格線',
  };

  static const _componentLabels = {
    'water': '💧 飲水提醒卡片',
    'selftest': '🧠 自測提醒卡片',
    'worktimer': '⏱ 連續工時卡片',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final c = _service.customization;
        return Scaffold(
          appBar: AppBar(
            title: const Text('外觀客製化'),
            actions: [
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: '恢復預設',
                onPressed: () async {
                  await _service.resetAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('已恢復預設外觀')));
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('背景顏色'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorSwatches.map((color) {
                  final selected = c.backgroundType == BackgroundType.color &&
                      c.backgroundColorValue == color.toARGB32();
                  return GestureDetector(
                    onTap: () => _service.setBackgroundColor(color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.teal : Colors.grey.shade400,
                          width: selected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _sectionTitle('背景圖案'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _patterns.map((id) {
                  final selected =
                      c.backgroundType == BackgroundType.pattern && c.backgroundPatternId == id;
                  return GestureDetector(
                    onTap: () => _service.setBackgroundPattern(id),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? Colors.teal : Colors.grey.shade400,
                          width: selected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: PatternBackground(
                              patternId: id,
                              baseColor: Colors.white,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _patternLabels[id]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _sectionTitle('自訂背景圖片'),
              if (c.backgroundType == BackgroundType.image && c.backgroundImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(c.backgroundImagePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await _service.pickBackgroundImage();
                        if (context.mounted && !ok) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('未選擇圖片')));
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('上傳圖片當背景'),
                    ),
                  ),
                  if (c.backgroundType == BackgroundType.image) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '移除背景圖片',
                      onPressed: _service.clearBackgroundImage,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('按鈕大小'),
              Slider(
                value: c.buttonScale,
                min: 0.8,
                max: 1.6,
                divisions: 8,
                label: '${(c.buttonScale * 100).round()}%',
                onChanged: (v) => _service.setButtonScale(v),
              ),
              Center(
                child: AppScaledButton(
                  icon: Icons.local_drink,
                  label: '按鈕預覽',
                  scale: c.buttonScale,
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('首頁卡片順序與顯示'),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '長按拖曳排序,關掉開關可以把不需要的卡片隱藏',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _service.reorderComponents,
                children: [
                  for (final id in c.componentOrder)
                    Card(
                      key: ValueKey(id),
                      child: ListTile(
                        leading: const Icon(Icons.drag_handle),
                        title: Text(_componentLabels[id] ?? id),
                        trailing: Switch(
                          value: c.componentVisible[id] ?? true,
                          onChanged: (v) => _service.setComponentVisible(id, v),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
}
