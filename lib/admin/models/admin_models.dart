class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.coverImage,
    required this.vocabulary,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String coverImage;
  final List<VocabularyWord> vocabulary;
  final DateTime createdAt;

  int get wordCount => vocabulary.length;

  Topic copyWith({
    String? id,
    String? name,
    String? coverImage,
    List<VocabularyWord>? vocabulary,
    DateTime? createdAt,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImage: coverImage ?? this.coverImage,
      vocabulary: vocabulary ?? this.vocabulary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': id,
      'topicName': name,
      'coverImage': coverImage,
      'createdAt': createdAt.toIso8601String(),
      'vocabulary': vocabulary.map((word) => word.toJson()).toList(),
    };
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['topicId'] as String,
      name: json['topicName'] as String,
      coverImage: json['coverImage'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      vocabulary: (json['vocabulary'] as List<dynamic>? ?? [])
          .map((item) => VocabularyWord.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VocabularyWord {
  const VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.imageUrl,
    required this.audioUrl,
  });

  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String imageUrl;
  final String audioUrl;

  Map<String, dynamic> toJson() {
    return {
      'wordId': id,
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    };
  }

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['wordId'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      pronunciation: json['pronunciation'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
    );
  }
}

class AiScenario {
  const AiScenario({
    required this.id,
    required this.title,
    required this.systemPrompt,
    required this.difficulty,
  });

  final String id;
  final String title;
  final String systemPrompt;
  final String difficulty;

  AiScenario copyWith({
    String? id,
    String? title,
    String? systemPrompt,
    String? difficulty,
  }) {
    return AiScenario(
      id: id ?? this.id,
      title: title ?? this.title,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenarioId': id,
      'title': title,
      'systemPrompt': systemPrompt,
      'difficulty': difficulty,
    };
  }

  factory AiScenario.fromJson(Map<String, dynamic> json) {
    return AiScenario(
      id: json['scenarioId'] as String,
      title: json['title'] as String,
      systemPrompt: json['systemPrompt'] as String,
      difficulty: json['difficulty'] as String,
    );
  }
}

class Quiz {
  const Quiz({
    required this.id,
    required this.topicId,
    required this.title,
    required this.questions,
  });

  final String id;
  final String topicId;
  final String title;
  final List<QuizQuestion> questions;

  Quiz copyWith({
    String? id,
    String? topicId,
    String? title,
    List<QuizQuestion>? questions,
  }) {
    return Quiz(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      questions: questions ?? this.questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': id,
      'topicId': topicId,
      'title': title,
      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['quizId'] as String,
      topicId: json['topicId'] as String? ?? '',
      title: json['title'] as String,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.rewardPoints,
  });

  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final int rewardPoints;

  Map<String, dynamic> toJson() {
    return {
      'questionId': id,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'rewardPoints': rewardPoints,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['questionId'] as String,
      questionText: json['questionText'] as String,
      options: List<String>.from(json['options'] as List<dynamic>? ?? []),
      correctAnswer: json['correctAnswer'] as String,
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserProgress {
  const UserProgress({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.learnedWords,
    required this.gameScore,
    required this.lastAccessed,
  });

  final String id;
  final String userId;
  final String topicId;
  final List<String> learnedWords;
  final int gameScore;
  final DateTime lastAccessed;

  UserProgress copyWith({
    String? id,
    String? userId,
    String? topicId,
    List<String>? learnedWords,
    int? gameScore,
    DateTime? lastAccessed,
  }) {
    return UserProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      learnedWords: learnedWords ?? this.learnedWords,
      gameScore: gameScore ?? this.gameScore,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progressId': id,
      'userId': userId,
      'topicId': topicId,
      'learnedWords': learnedWords,
      'gameScore': gameScore,
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['progressId'] as String,
      userId: json['userId'] as String,
      topicId: json['topicId'] as String,
      learnedWords: List<String>.from(
        json['learnedWords'] as List<dynamic>? ?? [],
      ),
      gameScore: (json['gameScore'] as num?)?.toInt() ?? 0,
      lastAccessed:
          DateTime.tryParse(json['lastAccessed'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
