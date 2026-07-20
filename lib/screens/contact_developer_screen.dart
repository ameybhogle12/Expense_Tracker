import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'troll_screen.dart';

class ContactDeveloperScreen extends StatefulWidget {
  const ContactDeveloperScreen({super.key});

  @override
  State<ContactDeveloperScreen> createState() => _ContactDeveloperScreenState();
}

class _ContactDeveloperScreenState extends State<ContactDeveloperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _contactController = TextEditingController();
  
  File? _attachedFile;
  String? _webFileName;
  List<int>? _webFileBytes;
  
  bool _isLoading = false;

  // Troll Easter Egg State
  int _trollState = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings_v1');
    _trollState = box.get('trollState', defaultValue: 0) as int;
    
    if (_trollState == 1) {
      // Auto-clear to state 2 if app closed during presentation
      Timer(const Duration(seconds: 4), () async {
        if (mounted) {
          setState(() {
            _trollState = 2;
          });
          await box.put('trollState', 2);
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
        });
      } else if (result != null && kIsWeb && result.files.single.bytes != null) {
        setState(() {
          _webFileName = result.files.single.name;
          _webFileBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick screenshot')),
        );
      }
    }
  }

  void _removeScreenshot() {
    setState(() {
      _attachedFile = null;
      _webFileName = null;
      _webFileBytes = null;
    });
  }

  Future<void> _triggerTroll() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrollScreen()),
    );
    
    if (!mounted) return;
    
    setState(() {
      _trollState = 1;
    });
    
    final box = Hive.box('settings_v1');
    await box.put('trollState', 1);

    // Play cat laugh sound effect
    try {
      await _audioPlayer.play(AssetSource('meme/cat-laugh-meme-1.mp3'));
    } catch (e) {
      debugPrint("Audio play error: $e");
    }

    // Dismiss the easter egg after 4 seconds
    Timer(const Duration(seconds: 4), () async {
      if (mounted) {
        setState(() {
          _trollState = 2;
        });
        await box.put('trollState', 2);
      }
    });
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final webhookUrl = dotenv.env['DISCORD_WEBHOOK_URL'];
    if (webhookUrl == null || webhookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Webhook URL is not configured.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(webhookUrl));
      
      final message = _messageController.text.trim();
      final contact = _contactController.text.trim().isEmpty ? 'Anonymous' : _contactController.text.trim();
      final platform = kIsWeb ? 'Web Browser' : Platform.operatingSystem;

      // Construct a beautiful Discord Embed payload
      final payload = {
        "username": "Trip & Track Feedback",
        "embeds": [
          {
            "title": "📬 New App Feedback",
            "color": 8415712, // Premium Deep Purple theme color as integer (0x8045E0)
            "fields": [
              {"name": "Sender / Contact Info", "value": contact, "inline": true},
              {"name": "Platform", "value": platform, "inline": true},
              {"name": "Message", "value": message}
            ],
            "timestamp": DateTime.now().toUtc().toIso8601String()
          }
        ]
      };

      request.fields['payload_json'] = jsonEncode(payload);

      // Attach file if present
      if (_attachedFile != null && !kIsWeb) {
        final multipartFile = await http.MultipartFile.fromPath(
          'files[0]',
          _attachedFile!.path,
        );
        request.files.add(multipartFile);
      } else if (kIsWeb && _webFileBytes != null && _webFileName != null) {
        final multipartFile = http.MultipartFile.fromBytes(
          'files[0]',
          _webFileBytes!,
          filename: _webFileName,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback sent! Thanks for helping improve the app.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Developer'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Greeting Card
                  Card(
                    elevation: 2,
                    color: isDark ? Colors.grey.shade900 : Colors.deepPurple.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Text(
                              'AB',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, I\'m Amey! 👋',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'I built Trip & Track to help keep spending simple. Found a bug, have a feature idea, or want to suggest a tweak? Send a message directly to me!',
                                  style: TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Troll Button Easter Egg Section (placed right after header for visibility)
                  if (_trollState < 2) ...[
                    const SizedBox(height: 16),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_trollState == 0)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.purpleAccent,
                                side: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                              onPressed: _triggerTroll,
                              icon: const Icon(Icons.warning_amber_rounded, size: 18),
                              label: const Text('Don\'t click, there is nothing here'),
                            )
                          else if (_trollState == 1) ...[
                            Text(
                              'Told you! 🤷‍♂️',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/meme/Cat laughing.png',
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  const SizedBox(height: 8),
                  
                  // Contact Details Input
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name or Email (Optional)',
                      hintText: 'So I can reach back out to you',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Message Input
                  TextFormField(
                    controller: _messageController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Your Message / Bug / Suggestion',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 90.0),
                        child: Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Screenshot Picker
                  if (_attachedFile != null || _webFileBytes != null) ...[
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: kIsWeb
                                ? const Icon(Icons.image, size: 50, color: Colors.grey)
                                : Image.file(_attachedFile!, fit: BoxFit.contain),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red.withOpacity(0.8),
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                onPressed: _removeScreenshot,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _pickScreenshot,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Attach Screenshot (Optional)'),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Message'),
                  ),

                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
