class Quiz {
  final int id;
  final String title;
  final String description;
  final String quizType;
  final String category;

  final int quizDuration; // Duration in minutes
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.quizType,
    required this.category,
    required this.quizDuration,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 0, // Default value for ID if null
      title: json['title'] ?? 'Untitled', // Default value for title if null
      description: json['description'] ??
          'No description', // Default value for description
      quizType: json['quiz_type'] ?? 'unknown', // Default for quiz type
      category: json['category'] ?? 'unknown', // Default for category
      quizDuration: json['quiz_duration'] ?? 0, // Default duration to 0 if null
      questions: (json['questions'] as List)
          .map((question) => Question.fromJson(question))
          .toList(),
    );
  }

  // Convert the Quiz object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'quiz_type': quizType,
      'category': category,
      'quiz_duration': quizDuration, // Duration in minutes
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

class Question {
  final int id;
  final String questionText;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctAnswer;

  Question({
    required this.id,
    required this.questionText,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0, // Default ID
      questionText:
          json['question_text'] ?? 'No question text', // Default question text
      optionA: json['option_a'], // Options can be null, so no default needed
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctAnswer: json['correct_answer'], // Optional field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
    };
  }
}
