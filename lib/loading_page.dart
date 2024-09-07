import 'package:flutter/material.dart';
import 'main.dart'; // Import the AuthPage

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    _loadAssetsAndNavigate();
  }

  Future<void> _loadAssetsAndNavigate() async {
    // Simulate a delay for loading assets
    await Future.delayed(Duration(seconds: 5));

    // Navigate to AuthPage after loading
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon.jpeg'), // Your loading image
            SizedBox(height: 20), // Space between the image and the text
            Text(
              'Sound of Meme', // Text to display below the icon
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Text color
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black, // Background color of the loading page
    );
  }
}
