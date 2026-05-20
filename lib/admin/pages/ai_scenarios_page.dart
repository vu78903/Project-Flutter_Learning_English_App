import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../models/admin_models.dart';
import '../widgets/admin_section.dart';

class AiScenariosPage extends StatelessWidget {
  const AiScenariosPage({
    required this.scenarios,
    required this.onSaveScenario,
    required this.onDeleteScenario,
    super.key,
  });

  final List<AiScenario> scenarios;
  final ValueChanged<AiScenario> onSaveScenario;
  final ValueChanged<String> onDeleteScenario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      children: [
        AdminActionButton(
          onPressed: () => _showScenarioDialog(context),
          icon: Icons.add,
          label: 'Thêm Kịch Bản',
        ),
        const SizedBox(height: 10),
        for (final scenario in scenarios)
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scenario.title,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _DifficultyBadge(scenario.difficulty),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    scenario.systemPrompt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    AdminSmallButton(
                      label: 'Chỉnh sửa',
                      onPressed: () =>
                          _showScenarioDialog(context, scenario: scenario),
                    ),
                    const SizedBox(width: 8),
                    AdminSmallButton(
                      label: 'Xóa',
                      color: Colors.red,
                      onPressed: () => onDeleteScenario(scenario.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showScenarioDialog(
    BuildContext context, {
    AiScenario? scenario,
  }) async {
    final titleController = TextEditingController(text: scenario?.title ?? '');
    final promptController = TextEditingController(
      text: scenario?.systemPrompt ?? '',
    );
    var difficulty = scenario?.difficulty ?? 'Beginner';

    final result = await showDialog<AiScenario>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            scenario == null ? 'Thêm kịch bản AI' : 'Sửa kịch bản AI',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tình huống',
                  ),
                ),
                TextField(
                  controller: promptController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'System Prompt'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: difficulty,
                  items: const [
                    DropdownMenuItem(value: 'Beginner', child: Text('Dễ')),
                    DropdownMenuItem(
                      value: 'Intermediate',
                      child: Text('Trung bình'),
                    ),
                    DropdownMenuItem(value: 'Advanced', child: Text('Khó')),
                  ],
                  onChanged: (value) =>
                      setState(() => difficulty = value ?? difficulty),
                  decoration: const InputDecoration(labelText: 'Độ khó'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  AiScenario(
                    id: scenario?.id ?? _newId('scenario'),
                    title: titleController.text.trim(),
                    systemPrompt: promptController.text.trim(),
                    difficulty: difficulty,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    promptController.dispose();

    if (result != null) {
      onSaveScenario(result);
    }
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge(this.difficulty);

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final color = difficulty == 'Advanced'
        ? Colors.red
        : difficulty == 'Intermediate'
        ? const Color(0xFFFFAA21)
        : const Color(0xFF2BB673);
    final label = difficulty == 'Advanced'
        ? 'Khó'
        : difficulty == 'Intermediate'
        ? 'Trung bình'
        : 'Dễ';

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    );
  }
}
