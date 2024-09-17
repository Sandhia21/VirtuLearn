class Note {
  final int id;
  final String title;
  final String content;
  final int moduleId; // Linking to the module the note belongs to

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.moduleId,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0, // Default value if 'id' is null
      title: json['title'] ?? 'Untitled', // Default value if 'title' is null
      content:
          json['content'] ?? 'No content', // Default value if 'content' is null
      moduleId: json['module'] ?? 0, // Default value for moduleId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'module': moduleId,
    };
  }
}
