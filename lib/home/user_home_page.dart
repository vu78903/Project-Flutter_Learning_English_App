import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../admin/models/admin_models.dart';
import '../admin/services/admin_database.dart';
import '../auth/models/app_user.dart';
import '../auth/services/user_database.dart';
import '../core/app_colors.dart';
import '../core/firebase_service.dart';
import '../user/services/ai_conversation_service.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({required this.user, super.key});

  final AppUser user;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _adminDatabase = AdminDatabase();
  final _userDatabase = UserDatabase();

  late AppUser _currentUser;
  List<AppUser> _users = [];
  AdminData? _adminData;
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadData();
  }

  Future<void> _loadData() async {
    final adminData = await _adminDatabase.getData();
    final users = await _userDatabase.getUsers();
    final latestUser = await _userDatabase.findByEmail(_currentUser.email);
    if (!mounted) {
      return;
    }
    setState(() {
      _adminData = adminData;
      _users = users;
      _currentUser = latestUser ?? _currentUser;
      _isLoading = false;
    });
  }

  Future<void> _markTopicLearned(Topic topic) async {
    final wordIds = topic.vocabulary.map((word) => word.id).toSet();
    final existingProgress = await _adminDatabase.findProgress(
      userId: _currentUser.id,
      topicId: topic.id,
    );
    final oldLearned = existingProgress?.learnedWords.toSet() ?? <String>{};
    final newLearned = {...oldLearned, ...wordIds}.toList();
    final gainedExp =
        (newLearned.length - oldLearned.length) *
        FirebaseService.intConfig('topic_word_reward', 10);

    await _adminDatabase.saveProgress(
      (existingProgress ??
              UserProgress(
                id: _newId('progress'),
                userId: _currentUser.id,
                topicId: topic.id,
                learnedWords: const [],
                gameScore: 0,
                lastAccessed: DateTime.now(),
              ))
          .copyWith(learnedWords: newLearned, lastAccessed: DateTime.now()),
    );

    if (gainedExp > 0) {
      await _addExpAndRefreshStreak(gainedExp);
      await FirebaseService.logEvent(
        'topic_completed',
        parameters: {'topic_id': topic.id, 'gained_exp': gainedExp},
      );
    }

    _showMessage(
      gainedExp > 0
          ? 'Đã học xong ${topic.name}. +$gainedExp EXP'
          : 'Bạn đã hoàn thành chủ đề này rồi.',
    );
    await _loadData();
  }

  Future<void> _completeQuiz(
    Quiz quiz,
    QuizQuestion question,
    String answer,
  ) async {
    final isCorrect = answer == question.correctAnswer;
    final existingProgress = await _adminDatabase.findProgress(
      userId: _currentUser.id,
      topicId: quiz.topicId,
    );
    final reward = isCorrect ? question.rewardPoints : 0;

    await _adminDatabase.saveProgress(
      (existingProgress ??
              UserProgress(
                id: _newId('progress'),
                userId: _currentUser.id,
                topicId: quiz.topicId,
                learnedWords: const [],
                gameScore: 0,
                lastAccessed: DateTime.now(),
              ))
          .copyWith(
            gameScore: (existingProgress?.gameScore ?? 0) + reward,
            lastAccessed: DateTime.now(),
          ),
    );

    if (reward > 0) {
      await _addExpAndRefreshStreak(reward);
      await FirebaseService.logEvent(
        'quiz_correct',
        parameters: {'quiz_id': quiz.id, 'question_id': question.id},
      );
    }

    _showMessage(
      isCorrect
          ? 'Chính xác! +$reward EXP'
          : 'Chưa đúng. Đáp án: ${question.correctAnswer}',
    );
    await _loadData();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addExpAndRefreshStreak(int exp) async {
    final latestUser =
        await _userDatabase.findByEmail(_currentUser.email) ?? _currentUser;
    final today = DateTime.now();
    final lastStudyDate = latestUser.lastStudyDate;
    final isSameDay =
        lastStudyDate != null &&
        lastStudyDate.year == today.year &&
        lastStudyDate.month == today.month &&
        lastStudyDate.day == today.day;
    final wasYesterday =
        lastStudyDate != null &&
        DateTime(today.year, today.month, today.day)
                .difference(
                  DateTime(
                    lastStudyDate.year,
                    lastStudyDate.month,
                    lastStudyDate.day,
                  ),
                )
                .inDays ==
            1;

    final nextStreak = isSameDay
        ? latestUser.currentStreak
        : wasYesterday
        ? latestUser.currentStreak + 1
        : 1;

    final updatedUser = latestUser.copyWith(
      totalExp: latestUser.totalExp + exp,
      currentStreak: nextStreak,
      lastStudyDate: today,
    );
    await _userDatabase.updateUser(updatedUser);
    if (mounted) {
      setState(() => _currentUser = updatedUser);
    }
  }

  Future<void> _rewardAiPractice(int exp) async {
    await _addExpAndRefreshStreak(exp);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final adminData = _adminData;
    final pages = adminData == null
        ? <Widget>[]
        : [
            _LearnPage(
              topics: adminData.topics,
              progress: adminData.progress
                  .where((item) => item.userId == _currentUser.id)
                  .toList(),
              onLearnTopic: _markTopicLearned,
            ),
            _RoleplayPage(
              scenarios: adminData.scenarios,
              user: _currentUser,
              onPracticeReward: _rewardAiPractice,
            ),
            _QuizPage(
              quizzes: adminData.quizzes,
              topics: adminData.topics,
              onAnswer: _completeQuiz,
            ),
            _ProgressPage(
              user: _currentUser,
              allUsers: _users,
              topics: adminData.topics,
              progress: adminData.progress
                  .where((item) => item.userId == _currentUser.id)
                  .toList(),
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading || adminData == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _UserHeader(user: _currentUser),
                  Expanded(child: pages[_selectedIndex]),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Học'),
          NavigationDestination(icon: Icon(Icons.mic), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'Game'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Tiến độ'),
        ],
      ),
    );
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${user.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.totalExp} EXP • ${user.currentStreak} ngày streak • ${_rankFor(user.totalExp)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

String _rankFor(int exp) {
  if (exp >= FirebaseService.intConfig('diamond_exp', 3000)) {
    return 'Diamond';
  }
  if (exp >= FirebaseService.intConfig('advanced_exp', 1500)) {
    return 'Gold';
  }
  if (exp >= FirebaseService.intConfig('intermediate_exp', 600)) {
    return 'Silver';
  }
  return 'Bronze';
}

String _unlockedDifficultyFor(int exp) {
  if (exp >= FirebaseService.intConfig('advanced_exp', 1500)) {
    return 'Đã mở khóa: Beginner, Intermediate, Advanced';
  }
  if (exp >= FirebaseService.intConfig('intermediate_exp', 600)) {
    return 'Đã mở khóa: Beginner, Intermediate';
  }
  return 'Đã mở khóa: Beginner';
}

int _previousMilestoneFor(int exp) {
  final intermediateExp = FirebaseService.intConfig('intermediate_exp', 600);
  final advancedExp = FirebaseService.intConfig('advanced_exp', 1500);
  final diamondExp = FirebaseService.intConfig('diamond_exp', 3000);
  if (exp >= diamondExp) {
    return diamondExp;
  }
  if (exp >= advancedExp) {
    return advancedExp;
  }
  if (exp >= intermediateExp) {
    return intermediateExp;
  }
  return 0;
}

int _nextMilestoneFor(int exp) {
  final intermediateExp = FirebaseService.intConfig('intermediate_exp', 600);
  final advancedExp = FirebaseService.intConfig('advanced_exp', 1500);
  final diamondExp = FirebaseService.intConfig('diamond_exp', 3000);
  if (exp < intermediateExp) {
    return intermediateExp;
  }
  if (exp < advancedExp) {
    return advancedExp;
  }
  if (exp < diamondExp) {
    return diamondExp;
  }
  return 5000;
}

String _nextMilestoneLabelFor(int exp) {
  if (exp < FirebaseService.intConfig('intermediate_exp', 600)) {
    return 'mở khóa Intermediate';
  }
  if (exp < FirebaseService.intConfig('advanced_exp', 1500)) {
    return 'mở khóa Advanced';
  }
  if (exp < FirebaseService.intConfig('diamond_exp', 3000)) {
    return 'lên Diamond';
  }
  return 'duy trì top bảng xếp hạng';
}

class _LearnPage extends StatelessWidget {
  const _LearnPage({
    required this.topics,
    required this.progress,
    required this.onLearnTopic,
  });

  final List<Topic> topics;
  final List<UserProgress> progress;
  final ValueChanged<Topic> onLearnTopic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        const _UserTitle('Chủ đề học tập'),
        for (final topic in topics)
          _UserCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: const Icon(Icons.school, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic.name, style: _titleStyle),
                          Text('${topic.wordCount} từ vựng', style: _subStyle),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: topic.vocabulary.isEmpty
                          ? null
                          : () => onLearnTopic(topic),
                      child: const Text('Học'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final word in topic.vocabulary)
                      Chip(
                        backgroundColor: AppColors.background,
                        label: Text('${word.word} - ${word.meaning}'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã học: ${_learnedCount(topic.id)}/${topic.wordCount}',
                  style: _subStyle,
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _learnedCount(String topicId) {
    for (final item in progress) {
      if (item.topicId == topicId) {
        return item.learnedWords.length;
      }
    }
    return 0;
  }
}

class _RoleplayPage extends StatelessWidget {
  const _RoleplayPage({
    required this.scenarios,
    required this.user,
    required this.onPracticeReward,
  });

  final List<AiScenario> scenarios;
  final AppUser user;
  final Future<void> Function(int exp) onPracticeReward;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        const _UserTitle('Luyện nói AI Roleplay'),
        for (final scenario in scenarios)
          _UserCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smart_toy, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(scenario.title, style: _titleStyle)),
                    Text(
                      _isUnlocked(scenario) ? scenario.difficulty : 'Đang khóa',
                      style: _subStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(scenario.systemPrompt, style: _subStyle),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isUnlocked(scenario)
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _AiConversationPage(
                                scenario: scenario,
                                onPracticeReward: onPracticeReward,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.mic),
                  label: Text(
                    _isUnlocked(scenario)
                        ? 'Bắt đầu luyện nói'
                        : 'Cần thêm ${_requiredExp(scenario) - user.totalExp} EXP',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isUnlocked(AiScenario scenario) {
    return user.totalExp >= _requiredExp(scenario);
  }

  int _requiredExp(AiScenario scenario) {
    if (scenario.difficulty == 'Advanced') {
      return FirebaseService.intConfig('advanced_exp', 1500);
    }
    if (scenario.difficulty == 'Intermediate') {
      return FirebaseService.intConfig('intermediate_exp', 600);
    }
    return 0;
  }
}

class _AiConversationPage extends StatefulWidget {
  const _AiConversationPage({
    required this.scenario,
    required this.onPracticeReward,
  });

  final AiScenario scenario;
  final Future<void> Function(int exp) onPracticeReward;

  @override
  State<_AiConversationPage> createState() => _AiConversationPageState();
}

class _AiConversationPageState extends State<_AiConversationPage> {
  final _aiService = AiConversationService();
  final _speechToText = SpeechToText();
  final _tts = FlutterTts();
  final _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startConversation();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _speechToText.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = true);
      }
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
    _tts.setErrorHandler((_) {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<void> _startConversation() async {
    await _configureTts();
    if (!mounted) {
      return;
    }
    setState(() => _isThinking = true);

    late final String opening;
    try {
      opening = await _aiService.generateOpening(scenario: widget.scenario);
    } on AiConversationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isThinking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(
        _ChatMessage(
          fromAi: true,
          text: opening,
          feedback: 'Mục tiêu: nghe, trả lời bằng giọng nói hoặc nhập câu.',
        ),
      );
      _isThinking = false;
    });
    await _speak(opening);
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty || _isThinking || _isSpeaking) {
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
    }
    setState(() {
      _messages.add(_ChatMessage(fromAi: false, text: text));
      _isThinking = true;
      _isListening = false;
      _messageController.clear();
    });

    late final String aiReply;
    try {
      aiReply = await _aiService.generateReply(
        scenario: widget.scenario,
        history: _messages
            .map(
              (message) => AiTurn(fromAi: message.fromAi, text: message.text),
            )
            .toList(),
        userText: text,
      );
    } on AiConversationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isThinking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    if (!mounted) {
      return;
    }

    final reward = _practiceRewardFor(text);
    await widget.onPracticeReward(reward);
    await FirebaseService.logEvent(
      'ai_speaking_turn_completed',
      parameters: {'scenario_id': widget.scenario.id, 'reward': reward},
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          fromAi: true,
          text: aiReply,
          feedback: '${_feedbackFor(text)} +$reward EXP luyện nói.',
        ),
      );
      _isThinking = false;
    });
    await _speak(aiReply);
  }

  Future<void> _toggleListening() async {
    if (_isSpeaking || _isThinking) {
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speechToText.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị chưa cho phép ghi âm.')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    await _speechToText.listen(
      listenOptions: SpeechListenOptions(localeId: 'en_US'),
      onResult: (result) {
        setState(() => _messageController.text = result.recognizedWords);
        if (result.finalResult) {
          _speechToText.stop();
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _speak(String text) async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
    await _tts.stop();
    if (mounted) {
      setState(() => _isSpeaking = true);
    }
    try {
      await _tts.speak(text);
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.scenario.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Text(
                '${_aiService.providerLabel} • ${widget.scenario.difficulty}\n${widget.scenario.systemPrompt}',
                style: _subStyle,
              ),
            ),
            Expanded(
              child: _messages.isEmpty && _isThinking
                  ? Center(
                      child: Text(
                        'Owl Alpha đang bắt đầu hội thoại...',
                        style: _subStyle,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message.fromAi
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: message.fromAi
                                  ? AppColors.surface
                                  : AppColors.primary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.stroke),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.text,
                                  style: _titleStyle.copyWith(fontSize: 13),
                                ),
                                if (message.feedback != null) ...[
                                  const SizedBox(height: 7),
                                  Text(message.feedback!, style: _subStyle),
                                ],
                                if (message.fromAi) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      tooltip: 'Nghe lại',
                                      onPressed: _isSpeaking
                                          ? null
                                          : () => _speak(message.text),
                                      icon: const Icon(
                                        Icons.volume_up,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            _SuggestionBar(
              suggestions: _suggestions(widget.scenario),
              onSelected: _sendMessage,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu trả lời tiếng Anh...',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _isSpeaking
                        ? 'Đợi AI nói xong'
                        : _isListening
                        ? 'Dừng ghi âm'
                        : 'Ghi âm câu trả lời',
                    onPressed: (_isSpeaking || _isThinking)
                        ? null
                        : _toggleListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: (_isThinking || _isSpeaking)
                        ? null
                        : () => _sendMessage(),
                    icon: _isThinking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _practiceRewardFor(String text) {
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    if (wordCount >= 10) {
      return FirebaseService.intConfig('speaking_long_reward', 25);
    }
    if (wordCount >= 5) {
      return FirebaseService.intConfig('speaking_medium_reward', 18);
    }
    return FirebaseService.intConfig('speaking_short_reward', 10);
  }

  String _feedbackFor(String text) {
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    if (wordCount < 3) {
      return 'Gợi ý: hãy trả lời thành câu đầy đủ, ví dụ “I would like water, please.”';
    }
    if (!RegExp(r"^[A-Za-z0-9 ,.?!'-]+$").hasMatch(text)) {
      return 'Gợi ý: phần luyện nói nên dùng tiếng Anh để AI đánh giá chính xác hơn.';
    }
    final lowerText = text.toLowerCase();
    if (lowerText.contains('please') || lowerText.contains('thank')) {
      return 'Tốt: câu lịch sự và đủ rõ. Hãy tiếp tục trả lời theo tình huống.';
    }
    if (wordCount >= 7) {
      return 'Tốt: câu đủ ý. Bạn có thể thêm chi tiết nếu AI hỏi tiếp.';
    }
    return 'Ổn: câu hiểu được. Nếu muốn tự nhiên hơn, hãy thêm một chi tiết ngắn.';
  }

  List<String> _suggestions(AiScenario scenario) {
    final title = scenario.title.toLowerCase();
    if (title.contains('nhà hàng')) {
      return [
        'I would like chicken, please.',
        'Can I have water?',
        'How much is it?',
      ];
    }
    if (title.contains('sân bay')) {
      return ['Here is my passport.', 'I fly to Singapore.', 'I have one bag.'];
    }
    if (title.contains('phỏng vấn')) {
      return [
        'I am a student.',
        'My strength is teamwork.',
        'I want to learn more.',
      ];
    }
    return ['Can you repeat that?', 'I need some help.', 'That sounds good.'];
  }
}

class _ChatMessage {
  const _ChatMessage({required this.fromAi, required this.text, this.feedback});

  final bool fromAi;
  final String text;
  final String? feedback;
}

class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({required this.suggestions, required this.onSelected});

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => ActionChip(
          backgroundColor: AppColors.surfaceSoft,
          label: Text(suggestions[index]),
          onPressed: () => onSelected(suggestions[index]),
        ),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }
}

class _QuizPage extends StatefulWidget {
  const _QuizPage({
    required this.quizzes,
    required this.topics,
    required this.onAnswer,
  });

  final List<Quiz> quizzes;
  final List<Topic> topics;
  final void Function(Quiz quiz, QuizQuestion question, String answer) onAnswer;

  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  final Map<String, String> _selectedAnswers = {};
  final Map<String, String> _submittedAnswers = {};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        const _UserTitle('Mini-game Quiz'),
        for (final quiz in widget.quizzes)
          _UserCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title, style: _titleStyle),
                Text('Chủ đề: ${_topicName(quiz.topicId)}', style: _subStyle),
                const SizedBox(height: 10),
                for (final question in quiz.questions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.questionText,
                          style: _titleStyle.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        for (final option in question.options)
                          _QuizOptionTile(
                            option: option,
                            isSelected: _selectedAnswers[question.id] == option,
                            state: _optionState(question, option),
                            onTap: _submittedAnswers.containsKey(question.id)
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAnswers[question.id] = option;
                                    });
                                  },
                          ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed:
                                _submittedAnswers.containsKey(question.id)
                                ? null
                                : () => _submitAnswer(quiz, question),
                            icon: const Icon(Icons.check),
                            label: Text(
                              _submittedAnswers.containsKey(question.id)
                                  ? 'Đã nộp'
                                  : 'Submit',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  _QuizOptionState _optionState(QuizQuestion question, String option) {
    final submittedAnswer = _submittedAnswers[question.id];
    if (submittedAnswer == null) {
      return _QuizOptionState.pending;
    }
    if (option == question.correctAnswer) {
      return _QuizOptionState.correct;
    }
    if (option == submittedAnswer) {
      return _QuizOptionState.wrong;
    }
    return _QuizOptionState.pending;
  }

  void _submitAnswer(Quiz quiz, QuizQuestion question) {
    final selectedAnswer = _selectedAnswers[question.id];
    if (selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn một đáp án trước khi Submit.')),
      );
      return;
    }
    setState(() {
      _submittedAnswers[question.id] = selectedAnswer;
    });
    widget.onAnswer(quiz, question, selectedAnswer);
  }

  String _topicName(String topicId) {
    for (final topic in widget.topics) {
      if (topic.id == topicId) {
        return topic.name;
      }
    }
    return 'Chưa gán';
  }
}

enum _QuizOptionState { pending, correct, wrong }

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.option,
    required this.isSelected,
    required this.state,
    required this.onTap,
  });

  final String option;
  final bool isSelected;
  final _QuizOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForState();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(colors.icon, color: colors.foreground, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option,
                  style: _titleStyle.copyWith(
                    color: colors.foreground,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _QuizOptionColors _colorsForState() {
    if (state == _QuizOptionState.correct) {
      return _QuizOptionColors(
        background: Colors.green.withValues(alpha: 0.16),
        border: Colors.green,
        foreground: Colors.green.shade700,
        icon: Icons.check_circle,
      );
    }
    if (state == _QuizOptionState.wrong) {
      return _QuizOptionColors(
        background: Colors.red.withValues(alpha: 0.16),
        border: Colors.red,
        foreground: Colors.red.shade700,
        icon: Icons.cancel,
      );
    }
    return _QuizOptionColors(
      background: isSelected
          ? AppColors.primary.withValues(alpha: 0.14)
          : AppColors.surfaceSoft,
      border: isSelected ? AppColors.primary : AppColors.stroke,
      foreground: AppColors.text,
      icon: isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
    );
  }
}

class _QuizOptionColors {
  const _QuizOptionColors({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage({
    required this.user,
    required this.allUsers,
    required this.topics,
    required this.progress,
  });

  final AppUser user;
  final List<AppUser> allUsers;
  final List<Topic> topics;
  final List<UserProgress> progress;

  @override
  Widget build(BuildContext context) {
    final rankedUsers = allUsers.where((item) => !item.isAdmin).toList()
      ..sort((a, b) => b.totalExp.compareTo(a.totalExp));
    final previousMilestone = _previousMilestoneFor(user.totalExp);
    final nextMilestone = _nextMilestoneFor(user.totalExp);
    final progressToNext =
        (user.totalExp - previousMilestone) /
        (nextMilestone - previousMilestone);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        const _UserTitle('Tiến độ cá nhân'),
        _UserCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: AppColors.primary,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${user.totalExp} EXP • ${_rankFor(user.totalExp)}\n${user.currentStreak} ngày streak • ${progress.length} chủ đề đã truy cập',
                      style: _titleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_unlockedDifficultyFor(user.totalExp), style: _subStyle),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressToNext.clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 6),
              Text(
                'Mốc tiếp theo: thêm ${nextMilestone - user.totalExp} EXP để ${_nextMilestoneLabelFor(user.totalExp)}',
                style: _subStyle,
              ),
            ],
          ),
        ),
        const _UserTitle('Bảng xếp hạng'),
        _UserCard(
          child: Column(
            children: [
              for (var index = 0; index < rankedUsers.take(5).length; index++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(rankedUsers[index].fullName, style: _titleStyle),
                  trailing: Text(
                    '${rankedUsers[index].totalExp} EXP',
                    style: _subStyle,
                  ),
                ),
            ],
          ),
        ),
        for (final item in progress)
          _UserCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_topicName(item.topicId), style: _titleStyle),
              subtitle: Text(
                'Đã học ${item.learnedWords.length} từ - Game: ${item.gameScore} điểm',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
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

class _UserCard extends StatelessWidget {
  const _UserCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: child,
    );
  }
}

class _UserTitle extends StatelessWidget {
  const _UserTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: AppColors.primaryDark,
  fontSize: 15,
  fontWeight: FontWeight.w900,
);

const _subStyle = TextStyle(
  color: AppColors.text,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);
