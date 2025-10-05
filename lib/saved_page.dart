import 'package:flutter/material.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Your saved posts will appear here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
