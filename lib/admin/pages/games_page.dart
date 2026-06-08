import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../models/admin_models.dart';
import '../widgets/admin_section.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({
    required this.quizzes,
    required this.topics,
    required this.onSaveQuiz,
    required this.onDeleteQuiz,
    super.key,
  });

  final List<Quiz> quizzes;
  final List<Topic> topics;
  final ValueChanged<Quiz> onSaveQuiz;
  final ValueChanged<String> onDeleteQuiz;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      children: [
        AdminActionButton(
          onPressed: () => _showQuizDialog(context),
          icon: Icons.add,
          label: 'Tạo Quiz Mới',
        ),
        const SizedBox(height: 10),
        for (final quiz in quizzes)
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${quiz.questions.length} câu hỏi - ${_topicName(quiz.topicId)}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdminSmallButton(
                      label: 'Sửa',
                      onPressed: () => _showQuizDialog(context, quiz: quiz),
                    ),
                    const SizedBox(width: 6),
                    AdminSmallButton(
                      label: 'Xóa',
                      color: Colors.red,
                      onPressed: () => onDeleteQuiz(quiz.id),
                    ),
                  ],
                ),
                if (quiz.questions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final question in quiz.questions.take(2))
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question.questionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${question.rewardPoints} EXP',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        AdminCard(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Điểm Thắng',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${quizzes.fold<int>(0, (sum, quiz) => sum + quiz.questions.fold<int>(0, (total, question) => total + question.rewardPoints))} EXP',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 95, child: CustomPaint(painter: _CityPainter())),
      ],
    );
  }

  Future<void> _showQuizDialog(BuildContext context, {Quiz? quiz}) async {
    final titleController = TextEditingController(text: quiz?.title ?? '');
    final questionController = TextEditingController(
      text: quiz?.questions.firstOrNull?.questionText ?? '',
    );
    final optionControllers = List.generate(
      4,
      (index) => TextEditingController(
        text:
            quiz != null &&
                quiz.questions.isNotEmpty &&
                quiz.questions.first.options.length > index
            ? quiz.questions.first.options[index]
            : '',
      ),
    );
    final rewardController = TextEditingController(
      text: (quiz?.questions.firstOrNull?.rewardPoints ?? 100).toString(),
    );
    var topicId = quiz?.topicId ?? (topics.isEmpty ? '' : topics.first.id);
    var correctAnswer = quiz?.questions.firstOrNull?.correctAnswer ?? '';

    final result = await showDialog<Quiz>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(quiz == null ? 'Tạo quiz' : 'Sửa quiz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tên quiz'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: topicId.isEmpty ? null : topicId,
                  items: topics
                      .map(
                        (topic) => DropdownMenuItem(
                          value: topic.id,
                          child: Text(topic.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => topicId = value ?? ''),
                  decoration: const InputDecoration(labelText: 'Chủ đề'),
                ),
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Câu hỏi'),
                ),
                for (var index = 0; index < optionControllers.length; index++)
                  TextField(
                    controller: optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Đáp án ${index + 1}',
                    ),
                  ),
                TextField(
                  controller: rewardController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Điểm thưởng EXP/Coin',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: correctAnswer.isEmpty ? null : correctAnswer,
                  items: optionControllers
                      .map((controller) => controller.text.trim())
                      .where((value) => value.isNotEmpty)
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onTap: () => setState(() {}),
                  onChanged: (value) =>
                      setState(() => correctAnswer = value ?? ''),
                  decoration: const InputDecoration(labelText: 'Đáp án đúng'),
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
                final options = optionControllers
                    .map((controller) => controller.text.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();
                if (titleController.text.trim().isEmpty ||
                    topicId.isEmpty ||
                    questionController.text.trim().isEmpty ||
                    options.length < 4) {
                  return;
                }
                Navigator.of(context).pop(
                  Quiz(
                    id: quiz?.id ?? _newId('quiz'),
                    topicId: topicId,
                    title: titleController.text.trim(),
                    questions: [
                      QuizQuestion(
                        id:
                            quiz?.questions.firstOrNull?.id ??
                            _newId('question'),
                        questionText: questionController.text.trim(),
                        options: options,
                        correctAnswer: correctAnswer.isEmpty
                            ? options.first
                            : correctAnswer,
                        rewardPoints:
                            int.tryParse(rewardController.text) ?? 100,
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      onSaveQuiz(result);
    }
  }

  String _topicName(String topicId) {
    for (final topic in topics) {
      if (topic.id == topicId) {
        return topic.name;
      }
    }
    return 'Chưa gán';
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

class _CityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF78C9F0);
    final dark = Paint()..color = const Color(0xFF4FB4E7);
    final widths = [22.0, 12.0, 18.0, 28.0, 14.0, 20.0, 12.0, 26.0];
    var x = 0.0;
    for (var index = 0; index < widths.length; index++) {
      final height = 18.0 + (index % 4) * 11;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - height, widths[index], height),
        index.isEven ? paint : dark,
      );
      x += widths[index] + 6;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
