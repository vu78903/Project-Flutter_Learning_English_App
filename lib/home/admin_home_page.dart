import 'package:flutter/material.dart';

import '../admin/pages/ai_scenarios_page.dart';
import '../admin/pages/dashboard_page.dart';
import '../admin/pages/games_page.dart';
import '../admin/pages/learning_material_page.dart';
import '../admin/pages/users_page.dart';
import '../admin/services/admin_database.dart';
import '../auth/models/app_user.dart';
import '../auth/services/user_database.dart';
import '../core/app_colors.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({required this.user, super.key});

  final AppUser user;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _adminDatabase = AdminDatabase();
  final _userDatabase = UserDatabase();

  int _selectedIndex = 0;
  List<AppUser> _users = [];
  AdminData? _adminData;
  bool _isLoading = true;

  final _menuItems = const [
    _AdminMenuItem('Dashboard', Icons.dashboard),
    _AdminMenuItem('Quản Lý Học liệu', Icons.menu_book),
    _AdminMenuItem('Kịch bản AI', Icons.smart_toy),
    _AdminMenuItem('Quản Lý Game', Icons.sports_esports),
    _AdminMenuItem('Người Dùng', Icons.people),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _userDatabase.getUsers();
    final adminData = await _adminDatabase.getData();
    if (!mounted) {
      return;
    }
    setState(() {
      _users = users;
      _adminData = adminData;
      _isLoading = false;
    });
  }

  Future<void> _saveAdminData(Future<void> Function() action) async {
    await action();
    await _loadData();
  }

  Future<void> _toggleUserActive(AppUser user) async {
    await _userDatabase.updateUser(user.copyWith(isActive: !user.isActive));
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final adminData = _adminData;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(child: _buildMenu(closeOnTap: true)),
      body: SafeArea(
        child: _isLoading || adminData == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final content = Column(
                    children: [
                      _AdminTopBar(title: _menuItems[_selectedIndex].label),
                      Expanded(child: _buildPage(adminData)),
                    ],
                  );
                  if (constraints.maxWidth < 760) {
                    return content;
                  }
                  return Row(
                    children: [
                      SizedBox(
                        width: 210,
                        child: _buildMenu(closeOnTap: false),
                      ),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMenu({required bool closeOnTap}) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LexiGo Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.user.email,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          for (var index = 0; index < _menuItems.length; index++)
            Builder(
              builder: (tileContext) => ListTile(
                selected: index == _selectedIndex,
                selectedColor: AppColors.primary,
                dense: true,
                leading: Icon(_menuItems[index].icon),
                title: Text(_menuItems[index].label),
                onTap: () {
                  setState(() => _selectedIndex = index);
                  if (closeOnTap) {
                    Navigator.of(tileContext).pop();
                  }
                },
              ),
            ),
          const Spacer(),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
            onTap: () {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPage(AdminData adminData) {
    return switch (_selectedIndex) {
      0 => DashboardPage(users: _users, adminData: adminData),
      1 => LearningMaterialPage(
        topics: adminData.topics,
        onSaveTopic: (topic) =>
            _saveAdminData(() => _adminDatabase.saveTopic(topic)),
        onDeleteTopic: (topicId) =>
            _saveAdminData(() => _adminDatabase.deleteTopic(topicId)),
      ),
      2 => AiScenariosPage(
        scenarios: adminData.scenarios,
        onSaveScenario: (scenario) =>
            _saveAdminData(() => _adminDatabase.saveScenario(scenario)),
        onDeleteScenario: (scenarioId) =>
            _saveAdminData(() => _adminDatabase.deleteScenario(scenarioId)),
      ),
      3 => GamesPage(
        quizzes: adminData.quizzes,
        topics: adminData.topics,
        onSaveQuiz: (quiz) =>
            _saveAdminData(() => _adminDatabase.saveQuiz(quiz)),
        onDeleteQuiz: (quizId) =>
            _saveAdminData(() => _adminDatabase.deleteQuiz(quizId)),
      ),
      _ => UsersPage(
        users: _users,
        progress: adminData.progress,
        topics: adminData.topics,
        onToggleActive: _toggleUserActive,
      ),
    };
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: AppColors.primaryDark),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
