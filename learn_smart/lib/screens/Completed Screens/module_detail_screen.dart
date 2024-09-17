import 'package:flutter/material.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:learn_smart/api_service.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/models/note.dart';
import 'package:learn_smart/models/quiz.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import 'quiz_detail_screen.dart';
import 'notes_detail_screen.dart';

class ModuleDetailScreen extends StatefulWidget {
  final int moduleId;

  ModuleDetailScreen({Key? key, required this.moduleId}) : super(key: key);

  @override
  _ModuleDetailScreenState createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen>
    with SingleTickerProviderStateMixin {
  String moduleTitle = "Loading...";
  String moduleDescription = "Loading description...";
  late TabController _tabController;
  late ApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');

      await _loadModuleDetails();
    });
  }

  Future<void> _loadModuleDetails() async {
    try {
      final module = DataStore.getModuleById(widget.moduleId);

      debugPrint(
          'Module details fetched: ${module?.title ?? "Unknown"}, ${module?.description ?? "No description available"}');

      setState(() {
        moduleTitle = module?.title ?? "Unknown Module Title";
        moduleDescription = module?.description ?? "No description available";
        _isLoading = false;
      });

      await _apiService.fetchNotes(widget.moduleId);
      await _apiService.fetchQuizzes(widget.moduleId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      debugPrint('Error while loading module details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: moduleTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModuleHeader(),
                    _buildTabs(),
                  ],
                ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildModuleHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moduleTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            moduleDescription,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blue,
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                indicator: BoxDecoration(),
                tabs: const [
                  Tab(text: "Notes"),
                  Tab(text: "Quizzes"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotesSection(),
                  _buildQuizzesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final notes = DataStore.getNotes(widget.moduleId);

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final Note note = notes[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple[100],
            child: const Icon(Icons.note, color: Colors.purple),
          ),
          title: Text(note.title ?? 'Untitled Note'),
          subtitle: Text(note.content ?? 'No content available'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotesDetailScreen(
                  noteId: note.id,
                  moduleId: widget.moduleId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizzesSection() {
    final quizzes = DataStore.getQuizzes(widget.moduleId);

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final Quiz quiz = quizzes[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.quiz, color: Colors.blue),
          ),
          title: Text(quiz.title ?? 'Untitled Quiz'),
          subtitle: Text(quiz.description ?? 'No description available'),
          onTap: () {
            final authViewModel =
                Provider.of<AuthViewModel>(context, listen: false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizDetailScreen(
                  quiz: quiz,
                  isStudentEnrolled: authViewModel.user.isStudent(),
                  moduleId: widget.moduleId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.user.role == 'student') {
          return Container();
        }

        return FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 0) {
              _showCreateNoteDialog(context);
            } else {
              _showCreateQuizDialog(context);
            }
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        );
      },
    );
  }

  void _showCreateNoteDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? _title;
    String? _content;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Note'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  onSaved: (value) {
                    _title = value;
                    debugPrint('Note title: $_title');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      debugPrint('Note title validation failed');
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Content'),
                  onSaved: (value) {
                    _content = value;
                    debugPrint('Note content: $_content');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      debugPrint('Note content validation failed');
                      return 'Please enter content';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await _apiService.createNote(
                      widget.moduleId,
                      _title ?? 'Untitled Note',
                      _content ?? 'No content provided');
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note created successfully')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateQuizDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? _title;
    String? _description;
    String? _quizType;
    String? _category;
    List<Map<String, dynamic>> questions = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Quiz'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  onSaved: (value) {
                    _title = value;
                    debugPrint('Quiz title: $_title');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      debugPrint('Quiz title validation failed');
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (value) {
                    _description = value;
                    debugPrint('Quiz description: $_description');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      debugPrint('Quiz description validation failed');
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quiz Type'),
                  onSaved: (value) {
                    _quizType = value;
                    debugPrint('Quiz type: $_quizType');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      debugPrint('Quiz type validation failed');
                      return 'Please enter the quiz type';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Category'),
                  onSaved: (value) {
                    _category = value;
                    debugPrint('Quiz category: $_category');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      debugPrint('Quiz category validation failed');
                      return 'Please enter the quiz category';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  debugPrint(
                      'Creating quiz with data: $_title, $_description, $_quizType, $_category');
                  await _apiService.createQuiz(
                    widget.moduleId,
                    _title ?? 'Untitled Quiz',
                    _description ?? 'No description provided',
                    _quizType ?? 'QNA',
                    _category ?? 'QNA',
                    questions,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz created successfully')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
