import 'package:flutter/material.dart';

import '../../auth/models/app_user.dart';
import '../../core/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_database.dart';
import '../widgets/admin_section.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.users,
    required this.adminData,
    super.key,
  });

  final List<AppUser> users;
  final AdminData adminData;

  @override
  Widget build(BuildContext context) {
    final learnerUsers = users.where((user) => !user.isAdmin).toList();
    final activeUsers = learnerUsers.where((user) => user.isActive).length;
    final newUsersThisWeek = learnerUsers.where((user) {
      return user.createdAt.isAfter(
        DateTime.now().subtract(const Duration(days: 7)),
      );
    }).length;
    final totalWords = adminData.topics.fold<int>(
      0,
      (sum, topic) => sum + topic.vocabulary.length,
    );
    final totalExp = learnerUsers.fold<int>(
      0,
      (sum, user) => sum + user.totalExp,
    );
    final averageExp = learnerUsers.isEmpty
        ? 0
        : totalExp ~/ learnerUsers.length;
    final missingMediaWords = adminData.topics
        .expand((topic) => topic.vocabulary)
        .where((word) => word.audioUrl.isEmpty || word.imageUrl.isEmpty)
        .length;
    final topicStudyCounts = _topicStudyCounts(
      adminData.topics,
      adminData.progress,
    );
    final topUsers = [...learnerUsers]
      ..sort((a, b) => b.totalExp.compareTo(a.totalExp));
    final recentProgress = [...adminData.progress]
      ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _MetricCard(
              title: 'Người dùng',
              value: learnerUsers.length.toString(),
              detail: '$activeUsers đang hoạt động',
              icon: Icons.people,
            ),
            _MetricCard(
              title: 'User mới tuần',
              value: newUsersThisWeek.toString(),
              detail: 'Tạo từ tài khoản thật',
              icon: Icons.person_add_alt_1,
            ),
            _MetricCard(
              title: 'Học liệu',
              value: '${adminData.topics.length}',
              detail: '$totalWords từ vựng',
              icon: Icons.menu_book,
            ),
            _MetricCard(
              title: 'EXP trung bình',
              value: averageExp.toString(),
              detail: '$totalExp EXP toàn hệ thống',
              icon: Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Chủ đề được học nhiều'),
              const SizedBox(height: 10),
              if (topicStudyCounts.isEmpty)
                const Text('Chưa có tiến độ học tập.', style: _smallTextStyle)
              else
                for (final entry in topicStudyCounts.entries.take(5))
                  _ProgressRow(
                    label: entry.key,
                    value: entry.value,
                    maxValue: topicStudyCounts.values.first,
                  ),
            ],
          ),
        ),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Cảnh báo nội dung'),
              const SizedBox(height: 8),
              _HealthRow(
                icon: Icons.image_not_supported,
                label: 'Từ vựng thiếu ảnh/audio',
                value: missingMediaWords.toString(),
                color: missingMediaWords == 0 ? Colors.green : Colors.orange,
              ),
              _HealthRow(
                icon: Icons.psychology,
                label: 'Kịch bản AI đã tạo',
                value: adminData.scenarios.length.toString(),
                color: AppColors.primary,
              ),
              _HealthRow(
                icon: Icons.quiz,
                label: 'Bộ quiz đang có',
                value: adminData.quizzes.length.toString(),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Top người học'),
              const SizedBox(height: 8),
              if (topUsers.isEmpty)
                const Text('Chưa có user học tập.', style: _smallTextStyle)
              else
                for (var index = 0; index < topUsers.take(5).length; index++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(topUsers[index].fullName),
                    subtitle: Text(topUsers[index].email),
                    trailing: Text(
                      '${topUsers[index].totalExp} EXP',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
            ],
          ),
        ),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Hoạt động gần đây'),
              const SizedBox(height: 8),
              if (recentProgress.isEmpty)
                const Text('Chưa có hoạt động.', style: _smallTextStyle)
              else
                for (final item in recentProgress.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(_userName(item.userId, learnerUsers)),
                    subtitle: Text(
                      '${_topicName(item.topicId)} • ${item.learnedWords.length} từ • ${item.gameScore} điểm game',
                    ),
                    trailing: Text(_shortDate(item.lastAccessed)),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, int> _topicStudyCounts(
    List<Topic> topics,
    List<UserProgress> progress,
  ) {
    final counts = <String, int>{};
    for (final topic in topics) {
      counts[topic.name] = progress
          .where((item) => item.topicId == topic.id)
          .fold<int>(
            0,
            (sum, item) =>
                sum + item.learnedWords.length + item.gameScore ~/ 50,
          );
    }
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  String _topicName(String topicId) {
    for (final topic in adminData.topics) {
      if (topic.id == topicId) {
        return topic.name;
      }
    }
    return 'Chủ đề đã xóa';
  }

  String _userName(String userId, List<AppUser> learnerUsers) {
    for (final user in learnerUsers) {
      if (user.id == userId) {
        return user.fullName;
      }
    }
    return userId;
  }

  String _shortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: _smallTextStyle),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _smallTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : value / maxValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$value lượt'),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

const _smallTextStyle = TextStyle(
  color: AppColors.text,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);
