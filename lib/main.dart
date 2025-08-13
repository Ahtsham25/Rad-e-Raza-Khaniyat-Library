import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const RadERazaKhaniyatApp());
}

class RadERazaKhaniyatApp extends StatelessWidget {
  const RadERazaKhaniyatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ردِّ رضا خانیت لائبریری',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class Book {
  final String title;
  final String author;
  final String url;
  Book(this.title, this.author, this.url);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Map<String, dynamic>>? futureJson;

  // اپنے GitHub یوزر نیم/ریپو سے Raw JSON URL بنائیں:
  static const String rawJsonUrl =
      'https://raw.githubusercontent.com/Ahtsham25/Rad-e-Raza-Khaniyat-Library/main/books.json';

  @override
  void initState() {
    super.initState();
    futureJson = _fetchJson();
  }

  Future<Map<String, dynamic>> _fetchJson() async {
    final r = await http.get(Uri.parse(rawJsonUrl));
    if (r.statusCode != 200) {
      throw Exception('JSON لوڈ نہیں ہوا: ${r.statusCode}');
    }
    final body = r.body.trim();
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else {
      // اگر اوپر array ہوا تو ایک default category میں رکھ دیں
      return {
        "کتابیں": decoded,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality( // RTL کے لیے
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ردِّ رضا خانیت لائبریری')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: futureJson,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('خرابی: ${snap.error}'));
            }
            final data = snap.data!;
            final categoryNames = data.keys.toList();

            return ListView.builder(
              itemCount: categoryNames.length,
              itemBuilder: (context, index) {
                final cat = categoryNames[index];
                final value = data[cat];

                // اگر براہ راست کتابوں کی لسٹ ہے (List)
                if (value is List) {
                  final books = _parseBookList(value);
                  return _CategoryTile(title: cat, books: books);
                }

                // اگر اندر sub-categories ہیں (Map)
                if (value is Map) {
                  final subNames = value.keys.toList();
                  return ExpansionTile(
                    title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      for (final sub in subNames)
                        _CategoryTile(title: "$cat › $sub", books: _parseBookList(value[sub]))
                    ],
                  );
                }

                return ListTile(title: Text(cat));
              },
            );
          },
        ),
      ),
    );
  }

  List<Book> _parseBookList(dynamic jsonList) {
    if (jsonList is! List) return [];
    return jsonList.map<Book>((e) {
      final m = e as Map<String, dynamic>;
      return Book(
        (m['title'] ?? '').toString(),
        (m['author'] ?? '').toString(),
        (m['url'] ?? '').toString(),
      );
    }).toList();
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final List<Book> books;
  const _CategoryTile({required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        for (final b in books)
          ListTile(
            title: Text(b.title),
            subtitle: Text(b.author),
            onTap: () async {
              final uri = Uri.parse(b.url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لنک نہیں کھلا')),
                );
              }
            },
          )
      ],
    );
  }
}
