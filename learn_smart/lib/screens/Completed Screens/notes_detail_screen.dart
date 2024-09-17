import 'package:flutter/material.dart';
import 'package:learn_smart/api_service.dart';
import 'package:learn_smart/models/datastore.dart';
import 'package:learn_smart/models/note.dart';
import 'package:learn_smart/screens/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class NotesDetailScreen extends StatefulWidget {
  final int noteId;
  final int moduleId;

  NotesDetailScreen({Key? key, required this.noteId, required this.moduleId})
      : super(key: key);

  @override
  _NotesDetailScreenState createState() => _NotesDetailScreenState();
}

class _NotesDetailScreenState extends State<NotesDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late Note note;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _apiService = ApiService(baseUrl: 'http://10.0.2.2:8000/api/');
      _apiService.updateToken(authViewModel.user.token ?? '');

      await _loadNoteDetails();
    });
  }

  Future<void> _loadNoteDetails() async {
    try {
      // Fetch note details from DataStore or ApiService
      final noteList = DataStore.getNotes(widget.moduleId);
      note = noteList.firstWhere((n) => n.id == widget.noteId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _isLoading ? 'Loading...' : note.title),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          note.content,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
