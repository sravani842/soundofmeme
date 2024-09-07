import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import 'loading_page.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

// Authentication Service
class AuthService with ChangeNotifier {
  final Map<String, String> _users = {}; // Store username and password pairs
  String? _currentUser;

  bool get isAuthenticated => _currentUser != null;
  String? get currentUser => _currentUser;

  Future<void> signUp(String username, String password) async {
    if (_users.containsKey(username)) {
      throw Exception("User already exists");
    }
    _users[username] = password;
    _currentUser = username;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    if (_users[username] == password) {
      _currentUser = username;
      notifyListeners();
    } else {
      throw Exception("Invalid username or password");
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
 }


class MemeGenerator with ChangeNotifier {
  FlutterSoundPlayer? _player;
  bool _isPlaying = false;
  int? _currentlyPlayingIndex;
  final List<Meme> memes = [];
  final Map<String, ByteData> _imageCache = {};
  final Map<String, String> _soundCache = {};
  final List<bool> _isBlinking = [];

  MemeGenerator() {
    _player = FlutterSoundPlayer();
    _initializePlayer();
    _preloadAssets();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player!.openPlayer();
      print("Player initialized successfully.");
    } catch (e) {
      print("Error initializing player: $e");
    }
  }

  Future<void> _preloadAssets() async {
    try {
      _imageCache['dancing in the start dust'] = await rootBundle.load('assets/img3.jpeg');
      _imageCache['chris with you my love'] = await rootBundle.load('assets/img1.jpeg');
      _imageCache['default'] = await rootBundle.load('assets/img4.jpeg');

      _soundCache['hip hop'] = 'assets/hip_hop.mp3';
      _soundCache['classic'] = 'assets/classic.mp3';
      _soundCache['dancing in the start dust'] = 'assets/island-breeze-214305.mp3';
      _soundCache['chris with you my love'] = 'assets/loneliness_long-202383.mp3';
    } catch (e) {
      print("Error preloading assets: $e");
    }
  }

  bool get isPlaying => _isPlaying;
  int? get currentlyPlayingIndex => _currentlyPlayingIndex;

  Future<void> generateMeme(String prompt, String style) async {
    try {
      final String mood = _getMemeImage(prompt);
      final ByteData imageData = _imageCache[mood]!;
      final String imagePath = (await _writeToFile(imageData)).path;

      final String soundPath = _getMemeSound(prompt, style);
      final File soundFile = await _writeToFile(await rootBundle.load(soundPath));

      memes.add(Meme(image: File(imagePath), text: prompt, soundPath: soundFile.path));
      _isBlinking.add(false); // Initially not blinking
      notifyListeners();
    } catch (e) {
      print("Error generating meme: $e");
    }
  }

  String _getMemeImage(String prompt) {
    if (prompt.contains('dancing in the start dust')) {
      return 'dancing in the start dust';
    } else if (prompt.contains('chris with you my love')) {
      return 'chris with you my love';
    } else {
      return 'default';
    }
  }

  String _getMemeSound(String prompt, String style) {
    if (prompt.contains('dancing in the start dust')) {
      return _soundCache['dancing in the start dust']!;
    } else if (prompt.contains('chris with you my love')) {
      return _soundCache['chris with you my love']!;
    } else {
      return _soundCache[style] ?? _soundCache['classic']!;
    }
  }

  Future<File> _writeToFile(ByteData data) async {
    final buffer = data.buffer.asUint8List();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpeg');
    await file.writeAsBytes(buffer);
    return file;
  }

  Future<void> playSound(String path, int index) async {
    print('Requested sound path: $path');
    try {
      if (_isPlaying && _currentlyPlayingIndex == index) {
        await _player!.stopPlayer();
        _isPlaying = false;
        _currentlyPlayingIndex = null;
        _isBlinking[index] = false;
      } else {
        await _player!.startPlayer(
          fromURI: path,
          codec: Codec.mp3,
          whenFinished: () {
            _isPlaying = false;
            _currentlyPlayingIndex = null;
            _isBlinking[index] = false;
            notifyListeners();
          },
        );
        _isPlaying = true;
        _currentlyPlayingIndex = index;
        _isBlinking[index] = true;
        _startBlinking(index);
      }
      notifyListeners();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
  Future<void> testPlayback() async {
    try {
      await _player!.startPlayer(
        fromURI: 'assets/hip_hop.mp3',
        codec: Codec.mp3,
      );
    } catch (e) {
      print('Error playing sound for testing: $e');
    }
  }


  void _startBlinking(int index) async {
    while (_isPlaying && _currentlyPlayingIndex == index) {
      _isBlinking[index] = !_isBlinking[index];
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 500));
    }
    _isBlinking[index] = false;
    notifyListeners();
  }

  bool isMemeBlinking(int index) {
    return _isBlinking[index];
  }
}

class Meme {
  final File image;
  final String text;
  final String soundPath;

  Meme({required this.image, required this.text, required this.soundPath});
}


// Main App
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => MemeGenerator()),
      ],
      child: MemeApp(),
    ),
  );
}

class MemeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoadingPage(), // Start with LoadingPage
          theme: ThemeData(
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.black, // AppBar background color
              titleTextStyle: TextStyle(
                color: Colors.white, // AppBar text color
                fontSize: 24,
                fontFamily: 'PottaOne', // Font similar to "font-potta"
              ),
            ),
            scaffoldBackgroundColor: Colors.black, // Background color of the Scaffold
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent.shade400, // Button color
                foregroundColor: Colors.black, // Text color on the button
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Authentication Page
// Authentication Page
// Authentication Page

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignUp = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSignUp ? "Sign Up" : "Login"),
        backgroundColor: Colors.black,
        leading: isSignUp
            ? IconButton(
          icon: Text(
            'Exit',
            style: TextStyle(
              color: Colors.red, // Bright color for visibility
              fontSize: 18, // Larger font size
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            SystemNavigator.pop(); // Close the app
          },
        )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: "Username",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // Kelly green border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // Kelly green focused border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // Kelly green enabled border
                    ),
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // Kelly green border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // Kelly green focused border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // Kelly green enabled border
                    ),
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (isSignUp) {
                        await authService.signUp(
                          _usernameController.text,
                          _passwordController.text,
                        );
                        setState(() {
                          isSignUp = false; // Switch to login after signup
                          errorMessage = '';
                        });
                      } else {
                        await authService.login(
                          _usernameController.text,
                          _passwordController.text,
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainPage()),
                        );
                        setState(() {
                          errorMessage = '';
                        });
                      }
                    } catch (e) {
                      setState(() {
                        errorMessage = e.toString();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Kelly green background
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isSignUp ? "Sign Up" : "Login"),
                ),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isSignUp = !isSignUp;
                      errorMessage = '';
                    });
                  },
                  child: Text(
                    isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up",
                    style: TextStyle(color: Colors.green), // Kelly green text
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Main Page
// Main Page
// Main Page
// Main Page
class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final memeGenerator = Provider.of<MemeGenerator>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Creations',
          style: TextStyle(
            fontFamily: 'PottaOne', // Font style
            fontSize: 24,
            color: Colors.white, // Text color
          ),
        ),
        backgroundColor: Color(0xFF4e545c), // AppBar background color
        actions: [
          TextButton(
            onPressed: () {
              authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthPage()),
              );
            },
            child: Text(
              "Logout",
              style: TextStyle(color: Colors.green, fontSize: 16), // Kelly green text
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: memeGenerator.memes.isEmpty
                    ? Center(child: Text("No memes generated yet.", style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                  itemCount: memeGenerator.memes.length,
                  itemBuilder: (context, index) {
                    final meme = memeGenerator.memes[index];
                    final isBlinking = memeGenerator.isMemeBlinking(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0), // Adds vertical space between memes
                      child: AnimatedOpacity(
                        opacity: isBlinking ? 0.5 : 1.0, // Adjust the opacity for blinking effect
                        duration: Duration(milliseconds: 500),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 200, // Adjust the width of the meme image
                                height: 200, // Adjust the height of the meme image
                                child: FittedBox(
                                  fit: BoxFit.contain, // Ensure the meme is fully visible
                                  child: Image.file(meme.image),
                                ),
                              ),
                              SizedBox(width: 8), // Space between the meme image and the play button
                              GestureDetector(
                                onTap: () {
                                  memeGenerator.playSound(meme.soundPath, index);
                                },
                                child: CustomPaint(
                                  size: Size(40, 40),
                                  painter: PlayPauseButtonPainter(
                                    memeGenerator.isPlaying && memeGenerator.currentlyPlayingIndex == index,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Kelly green background
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateMemePage()),
                );
              },
              child: Text("Create Meme"),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayPauseButtonPainter extends CustomPainter {
  final bool isPlaying;

  PlayPauseButtonPainter(this.isPlaying);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);

    if (isPlaying) {
      paint.color = Colors.white;
      final double lineWidth = size.width / 8;
      final double lineHeight = size.height * 0.6;

      canvas.drawRect(
        Rect.fromLTWH(size.width / 4 - lineWidth / 2, size.height / 2 - lineHeight / 2, lineWidth, lineHeight),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width * 3 / 4 - lineWidth / 2, size.height / 2 - lineHeight / 2, lineWidth, lineHeight),
        paint,
      );
    } else {
      final Path path = Path()
        ..moveTo(size.width / 4, size.height / 4)
        ..lineTo(size.width * 3 / 4, size.height / 2)
        ..lineTo(size.width / 4, size.height * 3 / 4)
        ..close();
      paint.color = Colors.white;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}


class CreateMemePage extends StatefulWidget {
  @override
  _CreateMemePageState createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  final _promptController = TextEditingController();
  final _styleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final memeGenerator = Provider.of<MemeGenerator>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            // Home button aligned to the left
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()), // Navigate to MainPage
                );
              },
              child: Text(
                'Home',
                style: TextStyle(
                  color: Colors.green, // Kelly green color
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Spacer to push the title to the center
            Spacer(),
            // Title centered
            Text(
              'Create Meme',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Spacer to keep the title in the center
            Spacer(),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: "Enter a prompt sentence",
                border: OutlineInputBorder(),
                hintStyle: TextStyle(color: Colors.white70),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _styleController,
              decoration: InputDecoration(
                hintText: "Enter the music style (e.g., hip hop, classic)",
                border: OutlineInputBorder(),
                hintStyle: TextStyle(color: Colors.white70),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                memeGenerator.generateMeme(
                  _promptController.text,
                  _styleController.text,
                );
                Navigator.pop(context);
              },
              child: Text("Generate Meme"),
            ),
          ],
        ),
      ),
    );
  }
}





