class MemeGenerator with ChangeNotifier {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  int? _currentlyPlayingIndex;
  final List<Meme> memes = [];
  final List<bool> _isBlinking = [];

  final Map<String, ByteData> _imageCache = {};
  final Map<String, String> _soundCache = {};

  MemeGenerator() {
    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    try {
      _imageCache['dancing in the start dust'] = await rootBundle.load('assets/img3.jpeg');
      _imageCache['chris with you my love'] = await rootBundle.load('assets/img1.jpeg');
      _imageCache['default'] = await rootBundle.load('assets/img4.jpeg'); // Default image

      _soundCache['hip hop'] = 'assets/hip_hop.mp3';
      _soundCache['classic'] = 'assets/classic.mp3';
      _soundCache['dancing in the start dust'] = 'assets/dancing_in_the_start_dust.mp3';
      _soundCache['chris with you my love'] = 'assets/chris_with_you_my_love.mp3';
      _soundCache['default'] = 'assets/hip_hop.mp3'; // Default sound
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
      return _soundCache[style] ?? _soundCache['default']!;
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
    if (_isPlaying && _currentlyPlayingIndex == index) {
      await _player.stopPlayer();
      _isPlaying = false;
      _currentlyPlayingIndex = null;
      _isBlinking[index] = false;
    } else {
      await _player.startPlayer(
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
