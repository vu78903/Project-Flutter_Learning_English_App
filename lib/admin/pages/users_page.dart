import 'package:flutter/material.dart';

import '../../auth/models/app_user.dart';
import '../../core/app_colors.dart';
import '../models/admin_models.dart';
import '../widgets/admin_section.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({
    required this.users,
    required this.progress,
    required this.topics,
    required this.onToggleActive,
    super.key,
  });

  final List<AppUser> users;
  final List<UserProgress> progress;
  final List<Topic> topics;
  final ValueChanged<AppUser> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final learnerUsers = users.where((user) => !user.isAdmin).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      children: [
        AdminActionButton(
          label: 'Thêm Chủ Quản Mới',
          icon: Icons.add,
          onPressed: () {},
        ),
        const SizedBox(height: 10),
        AdminCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: const [
              Icon(Icons.search, size: 17, color: AppColors.primary),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tìm kiếm người dùng...',
                  style: TextStyle(color: AppColors.hint, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        if (learnerUsers.isEmpty)
          const AdminEmptyState('Chưa có người dùng nào đăng ký.')
        else
          for (final user in learnerUsers)
            AdminCard(
              child: InkWell(
                onTap: () => _showProgress(context, user),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Email: ${user.email}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Trạng thái:',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                user.isActive ? 'Kích Hoạt' : 'Đã Khóa',
                                style: TextStyle(
                                  color: user.isActive
                                      ? AppColors.primary
                                      : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user.totalExp} EXP',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AdminSmallButton(
                          label: user.isActive ? 'Khóa' : 'Mở',
                          color: user.isActive ? Colors.red : AppColors.primary,
                          onPressed: () => onToggleActive(user),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        SizedBox(height: 90, child: CustomPaint(painter: _CityPainter())),
      ],
    );
  }

  void _showProgress(BuildContext context, AppUser user) {
    final userProgress =
        progress.where((item) => item.userId == user.id).toList()
          ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tiến độ của ${user.fullName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (userProgress.isEmpty)
              const Text('Người dùng này chưa có tiến độ học tập.')
            else
              Expanded(
                child: ListView(
                  children: [
                    for (final item in userProgress)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_topicName(item.topicId)),
                        subtitle: Text(
                          'Đã học ${item.learnedWords.length} từ - Game: ${item.gameScore} điểm\nLần cuối: ${item.lastAccessed}',
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _topicName(String topicId) {
    for (final topic in topics) {
      if (topic.id == topicId) {
        return topic.name;
      }
    }
    return 'Chủ đề đã xóa';
  }
}

class _CityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFF92D9F7);
    final dark = Paint()..color = const Color(0xFF68C3EE);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 22, size.width, 22), light);
    for (var i = 0; i < 9; i++) {
      final width = 18.0 + (i % 3) * 6;
      final height = 24.0 + (i % 4) * 10;
      canvas.drawRect(
        Rect.fromLTWH(i * 34.0, size.height - height, width, height),
        i.isEven ? dark : light,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
