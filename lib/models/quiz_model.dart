class QuizModel {
  final int correctAnswers;
  final int totalQuestions;
  final int requiredCorrectAnswers;
  final bool isLoadingQuiz;

  QuizModel({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.requiredCorrectAnswers,
    required this.isLoadingQuiz,
  });

  QuizModel copyWith({
    int? correctAnswers,
    int? totalQuestions,
    int? requiredCorrectAnswers,
    bool? isLoadingQuiz,
  }) {
    return QuizModel(
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      requiredCorrectAnswers: requiredCorrectAnswers ?? this.requiredCorrectAnswers,
      isLoadingQuiz: isLoadingQuiz ?? this.isLoadingQuiz,
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final List<dynamic> optionsData = json['options'];
    String correctAnswer = '';
    List<String> options = [];
    
    for (var option in optionsData) {
      final String text = option['text'];
      final int value = option['value'];
      options.add(text);
      
      if (value == 1) {
        correctAnswer = text;
      }
    }

    return QuizQuestion(
      question: json['question'],
      options: options,
      correctAnswer: correctAnswer,
    );
  }
}