import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../models/admin_models.dart';
import '../widgets/admin_section.dart';

class LearningMaterialPage extends StatelessWidget {
  const LearningMaterialPage({
    required this.topics,
    required this.onSaveTopic,
    required this.onDeleteTopic,
    super.key,
  });

  final List<Topic> topics;
  final ValueChanged<Topic> onSaveTopic;
  final ValueChanged<String> onDeleteTopic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      children: [
        AdminActionButton(
          onPressed: () => _showTopicDialog(context),
          icon: Icons.add,
          label: 'Thêm Chủ Đề',
        ),
        const SizedBox(height: 10),
        for (final topic in topics)
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _TopicIcon(name: topic.name),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.name,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${topic.wordCount} từ vựng',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showVocabularyDialog(context, topic),
                      icon: const Icon(
                        Icons.volume_up,
                        color: Color(0xFFFFB547),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (topic.vocabulary.isNotEmpty) ...[
                  const Divider(height: 18),
                  Text(
                    'Từ vựng: ${topic.name}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final word in topic.vocabulary.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              word.word,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            word.meaning,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    AdminSmallButton(
                      label: 'Sửa',
                      onPressed: () => _showTopicDialog(context, topic: topic),
                    ),
                    const SizedBox(width: 8),
                    AdminSmallButton(
                      label: '+ Từ',
                      onPressed: () => _showVocabularyDialog(context, topic),
                    ),
                    const SizedBox(width: 8),
                    AdminSmallButton(
                      label: 'Xóa',
                      color: Colors.red,
                      onPressed: () => onDeleteTopic(topic.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showTopicDialog(BuildContext context, {Topic? topic}) async {
    final nameController = TextEditingController(text: topic?.name ?? '');
    final coverController = TextEditingController(
      text: topic?.coverImage ?? '',
    );

    final result = await showDialog<Topic>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(topic == null ? 'Thêm chủ đề' : 'Sửa chủ đề'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên chủ đề'),
            ),
            TextField(
              controller: coverController,
              decoration: const InputDecoration(
                labelText: 'Link ảnh bìa Firebase Storage',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.of(context).pop(
                Topic(
                  id: topic?.id ?? _newId('topic'),
                  name: name,
                  coverImage: coverController.text.trim(),
                  vocabulary: topic?.vocabulary ?? [],
                  createdAt: topic?.createdAt ?? DateTime.now(),
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    nameController.dispose();
    coverController.dispose();

    if (result != null) {
      onSaveTopic(result);
    }
  }

  Future<void> _showVocabularyDialog(BuildContext context, Topic topic) async {
    final wordController = TextEditingController();
    final meaningController = TextEditingController();
    final pronunciationController = TextEditingController();
    final imageController = TextEditingController();
    final audioController = TextEditingController();

    final word = await showDialog<VocabularyWord>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm từ vựng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: const InputDecoration(labelText: 'Từ vựng'),
              ),
              TextField(
                controller: meaningController,
                decoration: const InputDecoration(labelText: 'Nghĩa'),
              ),
              TextField(
                controller: pronunciationController,
                decoration: const InputDecoration(labelText: 'Phiên âm'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'Link ảnh minh họa',
                ),
              ),
              TextField(
                controller: audioController,
                decoration: const InputDecoration(labelText: 'Link file audio'),
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
              if (wordController.text.trim().isEmpty) {
                return;
              }
              Navigator.of(context).pop(
                VocabularyWord(
                  id: _newId('word'),
                  word: wordController.text.trim(),
                  meaning: meaningController.text.trim(),
                  pronunciation: pronunciationController.text.trim(),
                  imageUrl: imageController.text.trim(),
                  audioUrl: audioController.text.trim(),
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    wordController.dispose();
    meaningController.dispose();
    pronunciationController.dispose();
    imageController.dispose();
    audioController.dispose();

    if (word != null) {
      onSaveTopic(topic.copyWith(vocabulary: [...topic.vocabulary, word]));
    }
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

class _TopicIcon extends StatelessWidget {
  const _TopicIcon({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final icon = name.toLowerCase().contains('du')
        ? Icons.flight_takeoff
        : name.toLowerCase().contains('động')
        ? Icons.pets
        : Icons.shopping_bag;
    final color = name.toLowerCase().contains('du')
        ? const Color(0xFFFF8F3D)
        : name.toLowerCase().contains('động')
        ? const Color(0xFF47B885)
        : const Color(0xFFFF5D5D);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
