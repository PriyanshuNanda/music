import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/search_page.dart';
import 'viewmodels/search_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YMusic',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (_) => SearchViewModel(),
        child: const SearchPage(title: 'YMusic Search'),
      ),
    );
  }
}
