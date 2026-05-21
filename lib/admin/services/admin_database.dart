import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase_service.dart';
import '../models/admin_models.dart';

class AdminDatabase {
  AdminDatabase({File? databaseFile})
    : _databaseFile =
          databaseFile ??
          File('${Directory.systemTemp.path}/lexigo_admin_data.json');

  final File _databaseFile;

  Future<AdminData> getData() async {
    if (FirebaseService.isEnabled) {
      return _getFirebaseData();
    }

    await _seedIfNeeded();
    final rawData = await _databaseFile.readAsString();
    return AdminData.fromJson(jsonDecode(rawData) as Map<String, dynamic>);
  }

  Future<void> saveData(AdminData data) async {
    if (FirebaseService.isEnabled) {
      await _saveFirebaseData(data);
      return;
    }

    final encoder = const JsonEncoder.withIndent('  ');
    await _databaseFile.writeAsString(encoder.convert(data.toJson()));
  }

  Future<void> saveTopic(Topic topic) async {
    final data = await getData();
    final topics = [
      for (final item in data.topics)
        if (item.id == topic.id) topic else item,
    ];
    if (!data.topics.any((item) => item.id == topic.id)) {
      topics.add(topic);
    }
    await saveData(data.copyWith(topics: topics));
  }

  Future<void> deleteTopic(String topicId) async {
    if (FirebaseService.isEnabled) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.delete(firestore.collection('topics').doc(topicId));
      final quizzes = await firestore
          .collection('quizzes')
          .where('topicId', isEqualTo: topicId)
          .get();
      for (final quiz in quizzes.docs) {
        batch.delete(quiz.reference);
      }
      final progress = await firestore
          .collection('progress')
          .where('topicId', isEqualTo: topicId)
          .get();
      for (final item in progress.docs) {
        batch.delete(item.reference);
      }
      await batch.commit();
      return;
    }

    final data = await getData();
    await saveData(
      data.copyWith(
        topics: data.topics.where((topic) => topic.id != topicId).toList(),
        quizzes: data.quizzes.where((quiz) => quiz.topicId != topicId).toList(),
        progress: data.progress
            .where((item) => item.topicId != topicId)
            .toList(),
      ),
    );
  }

  Future<void> saveScenario(AiScenario scenario) async {
    final data = await getData();
    final scenarios = [
      for (final item in data.scenarios)
        if (item.id == scenario.id) scenario else item,
    ];
    if (!data.scenarios.any((item) => item.id == scenario.id)) {
      scenarios.add(scenario);
    }
    await saveData(data.copyWith(scenarios: scenarios));
  }

  Future<void> deleteScenario(String scenarioId) async {
    if (FirebaseService.isEnabled) {
      await FirebaseFirestore.instance
          .collection('ai_scenarios')
          .doc(scenarioId)
          .delete();
      return;
    }

    final data = await getData();
    await saveData(
      data.copyWith(
        scenarios: data.scenarios
            .where((scenario) => scenario.id != scenarioId)
            .toList(),
      ),
    );
  }

  Future<void> saveQuiz(Quiz quiz) async {
    final data = await getData();
    final quizzes = [
      for (final item in data.quizzes)
        if (item.id == quiz.id) quiz else item,
    ];
    if (!data.quizzes.any((item) => item.id == quiz.id)) {
      quizzes.add(quiz);
    }
    await saveData(data.copyWith(quizzes: quizzes));
  }

  Future<void> deleteQuiz(String quizId) async {
    if (FirebaseService.isEnabled) {
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .delete();
      return;
    }

    final data = await getData();
    await saveData(
      data.copyWith(
        quizzes: data.quizzes.where((quiz) => quiz.id != quizId).toList(),
      ),
    );
  }

  Future<void> saveProgress(UserProgress progress) async {
    final data = await getData();
    final progressItems = [
      for (final item in data.progress)
        if (item.id == progress.id) progress else item,
    ];
    if (!data.progress.any((item) => item.id == progress.id)) {
      progressItems.add(progress);
    }
    await saveData(data.copyWith(progress: progressItems));
  }

  Future<UserProgress?> findProgress({
    required String userId,
    required String topicId,
  }) async {
    if (FirebaseService.isEnabled) {
      final snapshot = await FirebaseFirestore.instance
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .where('topicId', isEqualTo: topicId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final doc = snapshot.docs.first;
      return UserProgress.fromJson({'progressId': doc.id, ...doc.data()});
    }

    final data = await getData();
    for (final item in data.progress) {
      if (item.userId == userId && item.topicId == topicId) {
        return item;
      }
    }
    return null;
  }

  Future<AdminData> _getFirebaseData() async {
    await _seedFirebaseIfNeeded();
    final firestore = FirebaseFirestore.instance;
    final topics = await firestore.collection('topics').get();
    final scenarios = await firestore.collection('ai_scenarios').get();
    final quizzes = await firestore.collection('quizzes').get();
    final progress = await firestore.collection('progress').get();

    return AdminData(
      topics: topics.docs
          .map((doc) => Topic.fromJson({'topicId': doc.id, ...doc.data()}))
          .toList(),
      scenarios: scenarios.docs
          .map(
            (doc) => AiScenario.fromJson({'scenarioId': doc.id, ...doc.data()}),
          )
          .toList(),
      quizzes: quizzes.docs
          .map((doc) => Quiz.fromJson({'quizId': doc.id, ...doc.data()}))
          .toList(),
      progress: progress.docs
          .map(
            (doc) =>
                UserProgress.fromJson({'progressId': doc.id, ...doc.data()}),
          )
          .toList(),
    );
  }

  Future<void> _saveFirebaseData(AdminData data) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final topic in data.topics) {
      batch.set(
        FirebaseFirestore.instance.collection('topics').doc(topic.id),
        topic.toJson(),
        SetOptions(merge: true),
      );
    }
    for (final scenario in data.scenarios) {
      batch.set(
        FirebaseFirestore.instance.collection('ai_scenarios').doc(scenario.id),
        scenario.toJson(),
        SetOptions(merge: true),
      );
    }
    for (final quiz in data.quizzes) {
      batch.set(
        FirebaseFirestore.instance.collection('quizzes').doc(quiz.id),
        quiz.toJson(),
        SetOptions(merge: true),
      );
    }
    for (final item in data.progress) {
      batch.set(
        FirebaseFirestore.instance.collection('progress').doc(item.id),
        item.toJson(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> _seedFirebaseIfNeeded() async {
    final topics = await FirebaseFirestore.instance
        .collection('topics')
        .limit(1)
        .get();
    if (topics.docs.isNotEmpty) {
      return;
    }
    await _saveFirebaseData(_sampleData());
  }

  Future<void> _seedIfNeeded() async {
    if (await _databaseFile.exists()) {
      await _mergeSampleDataIfNeeded();
      return;
    }

    await _databaseFile.create(recursive: true);
    await saveData(_sampleData());
  }

  Future<void> _mergeSampleDataIfNeeded() async {
    final rawData = await _databaseFile.readAsString();
    final currentData = AdminData.fromJson(
      jsonDecode(rawData) as Map<String, dynamic>,
    );
    final sampleData = _sampleData();
    final topics = [...currentData.topics];
    final scenarios = [...currentData.scenarios];
    final quizzes = [...currentData.quizzes];

    for (final topic in sampleData.topics) {
      if (!topics.any((item) => item.id == topic.id)) {
        topics.add(topic);
      }
    }
    for (final scenario in sampleData.scenarios) {
      if (!scenarios.any((item) => item.id == scenario.id)) {
        scenarios.add(scenario);
      }
    }
    for (final quiz in sampleData.quizzes) {
      if (!quizzes.any((item) => item.id == quiz.id)) {
        quizzes.add(quiz);
      }
    }

    if (topics.length != currentData.topics.length ||
        scenarios.length != currentData.scenarios.length ||
        quizzes.length != currentData.quizzes.length) {
      await saveData(
        currentData.copyWith(
          topics: topics,
          scenarios: scenarios,
          quizzes: quizzes,
        ),
      );
    }
  }

  AdminData _sampleData() {
    Topic topic(
      String id,
      String name,
      List<VocabularyWord> words,
      int daysAgo,
    ) {
      return Topic(
        id: id,
        name: name,
        coverImage: '',
        createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
        vocabulary: words,
      );
    }

    const travelTopicId = 'topic-travel';

    return AdminData(
      topics: [
        topic(travelTopicId, 'Du lịch', const [
          VocabularyWord(
            id: 'word-airport',
            word: 'Airport',
            meaning: 'Sân bay',
            pronunciation: '/ˈerpɔːrt/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-hotel',
            word: 'Hotel',
            meaning: 'Khách sạn',
            pronunciation: '/hoʊˈtel/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-passport',
            word: 'Passport',
            meaning: 'Hộ chiếu',
            pronunciation: '/ˈpæspɔːrt/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-ticket',
            word: 'Ticket',
            meaning: 'Vé',
            pronunciation: '/ˈtɪkɪt/',
            imageUrl: '',
            audioUrl: '',
          ),
        ], 10),
        topic('topic-animals', 'Động vật', const [
          VocabularyWord(
            id: 'word-cat',
            word: 'Cat',
            meaning: 'Con mèo',
            pronunciation: '/kæt/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-dog',
            word: 'Dog',
            meaning: 'Con chó',
            pronunciation: '/dɔːɡ/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-bird',
            word: 'Bird',
            meaning: 'Con chim',
            pronunciation: '/bɜːrd/',
            imageUrl: '',
            audioUrl: '',
          ),
        ], 8),
        topic('topic-shopping', 'Mua sắm', const [
          VocabularyWord(
            id: 'word-price',
            word: 'Price',
            meaning: 'Giá tiền',
            pronunciation: '/praɪs/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-discount',
            word: 'Discount',
            meaning: 'Giảm giá',
            pronunciation: '/ˈdɪskaʊnt/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-receipt',
            word: 'Receipt',
            meaning: 'Hóa đơn',
            pronunciation: '/rɪˈsiːt/',
            imageUrl: '',
            audioUrl: '',
          ),
        ], 5),
        topic('topic-food', 'Nhà hàng', const [
          VocabularyWord(
            id: 'word-menu',
            word: 'Menu',
            meaning: 'Thực đơn',
            pronunciation: '/ˈmenjuː/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-water',
            word: 'Water',
            meaning: 'Nước',
            pronunciation: '/ˈwɔːtər/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-bill',
            word: 'Bill',
            meaning: 'Hóa đơn',
            pronunciation: '/bɪl/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-delicious',
            word: 'Delicious',
            meaning: 'Ngon',
            pronunciation: '/dɪˈlɪʃəs/',
            imageUrl: '',
            audioUrl: '',
          ),
        ], 4),
        topic('topic-work', 'Công việc', const [
          VocabularyWord(
            id: 'word-meeting',
            word: 'Meeting',
            meaning: 'Cuộc họp',
            pronunciation: '/ˈmiːtɪŋ/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-deadline',
            word: 'Deadline',
            meaning: 'Hạn chót',
            pronunciation: '/ˈdedlaɪn/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-interview',
            word: 'Interview',
            meaning: 'Phỏng vấn',
            pronunciation: '/ˈɪntərvjuː/',
            imageUrl: '',
            audioUrl: '',
          ),
        ], 3),
        topic('topic-health', 'Sức khỏe', const [
          VocabularyWord(
            id: 'word-doctor',
            word: 'Doctor',
            meaning: 'Bác sĩ',
            pronunciation: '/ˈdɑːktər/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-medicine',
            word: 'Medicine',
            meaning: 'Thuốc',
            pronunciation: '/ˈmedɪsɪn/',
            imageUrl: '',
            audioUrl: '',
          ),
          VocabularyWord(
            id: 'word-headache',
            word: 'Headache',
            meaning: 'Đau đầu',
            pronunciation: '/ˈhedeɪk/',
            imageUrl: '',
            audioUrl: '',
          ),
        ], 2),
      ],
      scenarios: const [
        AiScenario(
          id: 'scenario-restaurant',
          title: 'Gọi món tại nhà hàng',
          systemPrompt:
              'Bạn là một người phục vụ nhà hàng khó tính. Hãy hỏi người dùng muốn ăn gì bằng tiếng Anh cơ bản.',
          difficulty: 'Beginner',
        ),
        AiScenario(
          id: 'scenario-airport',
          title: 'Làm thủ tục sân bay',
          systemPrompt:
              'Bạn là nhân viên sân bay. Hỏi hộ chiếu, vé máy bay và nơi đến của người dùng bằng tiếng Anh rõ ràng.',
          difficulty: 'Beginner',
        ),
        AiScenario(
          id: 'scenario-shopping',
          title: 'Mua áo tại cửa hàng',
          systemPrompt:
              'Bạn là nhân viên cửa hàng. Hỏi kích cỡ, màu sắc, ngân sách và đề xuất sản phẩm phù hợp.',
          difficulty: 'Intermediate',
        ),
        AiScenario(
          id: 'scenario-interview',
          title: 'Phỏng vấn xin việc',
          systemPrompt:
              'Bạn là nhà tuyển dụng. Hỏi kinh nghiệm, kỹ năng, điểm mạnh và lý do ứng tuyển bằng tiếng Anh.',
          difficulty: 'Advanced',
        ),
        AiScenario(
          id: 'scenario-clinic',
          title: 'Khám bệnh cơ bản',
          systemPrompt:
              'Bạn là bác sĩ phòng khám. Hỏi triệu chứng, thời gian bị bệnh và đưa lời khuyên đơn giản.',
          difficulty: 'Intermediate',
        ),
      ],
      quizzes: const [
        Quiz(
          id: 'quiz-travel',
          topicId: travelTopicId,
          title: 'Quiz Du lịch',
          questions: [
            QuizQuestion(
              id: 'question-airport',
              questionText: 'Airport nghĩa là gì?',
              options: ['Sân bay', 'Nhà hàng', 'Cửa hàng', 'Trường học'],
              correctAnswer: 'Sân bay',
              rewardPoints: 100,
            ),
            QuizQuestion(
              id: 'question-passport',
              questionText: 'Passport nghĩa là gì?',
              options: ['Hộ chiếu', 'Vé', 'Khách sạn', 'Sân bay'],
              correctAnswer: 'Hộ chiếu',
              rewardPoints: 80,
            ),
          ],
        ),
        Quiz(
          id: 'quiz-food',
          topicId: 'topic-food',
          title: 'Quiz Nhà hàng',
          questions: [
            QuizQuestion(
              id: 'question-menu',
              questionText: 'Menu nghĩa là gì?',
              options: ['Thực đơn', 'Bàn ăn', 'Đầu bếp', 'Nước'],
              correctAnswer: 'Thực đơn',
              rewardPoints: 90,
            ),
            QuizQuestion(
              id: 'question-bill',
              questionText: 'Bill trong nhà hàng là gì?',
              options: ['Hóa đơn', 'Món ăn', 'Dao', 'Ly'],
              correctAnswer: 'Hóa đơn',
              rewardPoints: 90,
            ),
          ],
        ),
        Quiz(
          id: 'quiz-work',
          topicId: 'topic-work',
          title: 'Quiz Công việc',
          questions: [
            QuizQuestion(
              id: 'question-meeting',
              questionText: 'Meeting nghĩa là gì?',
              options: ['Cuộc họp', 'Hạn chót', 'Phỏng vấn', 'Lương'],
              correctAnswer: 'Cuộc họp',
              rewardPoints: 110,
            ),
            QuizQuestion(
              id: 'question-deadline',
              questionText: 'Deadline nghĩa là gì?',
              options: ['Hạn chót', 'Kỹ năng', 'Máy tính', 'Đồng nghiệp'],
              correctAnswer: 'Hạn chót',
              rewardPoints: 110,
            ),
          ],
        ),
      ],
      progress: [
        UserProgress(
          id: 'progress-demo-admin',
          userId: 'admin-001',
          topicId: travelTopicId,
          learnedWords: const ['word-airport'],
          gameScore: 100,
          lastAccessed: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );
  }
}

class AdminData {
  const AdminData({
    required this.topics,
    required this.scenarios,
    required this.quizzes,
    required this.progress,
  });

  final List<Topic> topics;
  final List<AiScenario> scenarios;
  final List<Quiz> quizzes;
  final List<UserProgress> progress;

  AdminData copyWith({
    List<Topic>? topics,
    List<AiScenario>? scenarios,
    List<Quiz>? quizzes,
    List<UserProgress>? progress,
  }) {
    return AdminData(
      topics: topics ?? this.topics,
      scenarios: scenarios ?? this.scenarios,
      quizzes: quizzes ?? this.quizzes,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topics': topics.map((topic) => topic.toJson()).toList(),
      'ai_scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
      'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
      'user_progress': progress.map((item) => item.toJson()).toList(),
    };
  }

  factory AdminData.fromJson(Map<String, dynamic> json) {
    return AdminData(
      topics: (json['topics'] as List<dynamic>? ?? [])
          .map((item) => Topic.fromJson(item as Map<String, dynamic>))
          .toList(),
      scenarios: (json['ai_scenarios'] as List<dynamic>? ?? [])
          .map((item) => AiScenario.fromJson(item as Map<String, dynamic>))
          .toList(),
      quizzes: (json['quizzes'] as List<dynamic>? ?? [])
          .map((item) => Quiz.fromJson(item as Map<String, dynamic>))
          .toList(),
      progress: (json['user_progress'] as List<dynamic>? ?? [])
          .map((item) => UserProgress.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
