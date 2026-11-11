import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const RechercheApp());

// ---------- Normalisation du texte arabe ----------

final _tashkeelRe =
    RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08FF]');
final _alefRe = RegExp('[أإآٱ]');

const _dotMap = {
  'ب': 'ٮ', 'ت': 'ٮ', 'ث': 'ٮ', 'ن': 'ٮ', 'ي': 'ٮ', 'ى': 'ٮ', 'ئ': 'ٮ',
  'ج': 'ح', 'خ': 'ح', 'ذ': 'د', 'ز': 'ر', 'ش': 'س', 'ض': 'ص', 'ظ': 'ط',
  'غ': 'ع', 'ف': 'ڡ', 'ق': 'ڡ', 'ة': 'ه',
};

String normalize(String s,
    {required bool ignoreTashkeel, required bool ignoreDots}) {
  var t = s.replaceAll('\u0640', ''); // tatweel
  if (ignoreTashkeel) {
    t = t.replaceAll(_tashkeelRe, '');
    t = t.replaceAll(_alefRe, 'ا').replaceAll('ى', 'ي');
  }
  if (ignoreDots) {
    final b = StringBuffer();
    for (final ch in t.split('')) {
      b.write(_dotMap[ch] ?? ch);
    }
    t = b.toString();
  }
  return t;
}

int countSub(String text, String q) {
  if (q.isEmpty) return 0;
  var c = 0, i = 0;
  while ((i = text.indexOf(q, i)) != -1) {
    c++;
    i += q.length;
  }
  return c;
}

// ---------- Modèles ----------

class AyahData {
  final int number;
  final String text;
  AyahData(this.number, this.text);
}

class SurahData {
  final int number;
  final String name;
  final List<AyahData> ayahs;
  SurahData(this.number, this.name, this.ayahs);
}

class AyahHit {
  final int number;
  final String text;
  final int count;
  AyahHit(this.number, this.text, this.count);
}

class SurahResult {
  final SurahData surah;
  final int count;
  final List<AyahHit> hits;
  SurahResult(this.surah, this.count, this.hits);
}

// ---------- Application ----------

class RechercheApp extends StatelessWidget {
  const RechercheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بحث في القرآن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  late Future<List<SurahData>> _quran;
  List<SurahData> _surahs = [];

  bool _ignoreTashkeel = true;
  bool _ignoreDots = false;
  bool _exactWord = true;

  List<SurahResult> _results = [];
  int _total = 0;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _quran = _loadQuran();
  }

  Future<List<SurahData>> _loadQuran() async {
    final res = await http
        .get(Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'));
    if (res.statusCode != 200) throw Exception('Erreur de chargement');
    final data =
        jsonDecode(utf8.decode(res.bodyBytes))['data']['surahs'] as List;

    final list = <SurahData>[];
    for (final s in data) {
      final num = s['number'] as int;
      final ayahs = <AyahData>[];
      for (final a in s['ayahs']) {
        var text = a['text'] as String;
        final n = a['numberInSurah'] as int;
        // Retirer la basmala collée au 1er verset (sauf Fatiha et Tawba)
        if (n == 1 && num != 1 && num != 9) {
          final words = text.trim().split(RegExp(r'\s+'));
          if (words.length > 4) {
            final first4 = normalize(words.take(4).join(' '),
                ignoreTashkeel: true, ignoreDots: false);
            if (first4 == 'بسم الله الرحمن الرحيم') {
              text = words.skip(4).join(' ');
            }
          }
        }
        ayahs.add(AyahData(n, text));
      }
      list.add(SurahData(num, s['name'], ayahs));
    }
    _surahs = list;
    return list;
  }

  void _search() {
    FocusScope.of(context).unfocus();
    final q = normalize(_controller.text.trim(),
        ignoreTashkeel: _ignoreTashkeel, ignoreDots: _ignoreDots);
    if (q.isEmpty) return;

    final multiWord = q.contains(' ');
    final results = <SurahResult>[];
    var total = 0;

    for (final s in _surahs) {
      final hits = <AyahHit>[];
      var surahCount = 0;
      for (final a in s.ayahs) {
        var c = 0;
        if (multiWord) {
          final t = normalize(a.text,
              ignoreTashkeel: _ignoreTashkeel, ignoreDots: _ignoreDots);
          c = countSub(t, q);
        } else {
          for (final w in a.text.split(RegExp(r'\s+'))) {
            final nw = normalize(w,
                ignoreTashkeel: _ignoreTashkeel, ignoreDots: _ignoreDots);
            if (_exactWord) {
              if (nw == q) c++;
            } else {
              c += countSub(nw, q);
            }
          }
        }
        if (c > 0) {
          hits.add(AyahHit(a.number, a.text, c));
          surahCount += c;
        }
      }
      if (surahCount > 0) {
        results.add(SurahResult(s, surahCount, hits));
        total += surahCount;
      }
    }

    setState(() {
      _results = results;
      _total = total;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث في القرآن الكريم')),
      body: FutureBuilder<List<SurahData>>(
        future: _quran,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جارٍ تحميل المصحف...'),
              ],
            ));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تعذّر التحميل، تحقّق من الإنترنت'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => setState(() => _quran = _loadQuran()),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: 'اكتب كلمة...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('تجاهل التشكيل'),
            value: _ignoreTashkeel,
            onChanged: (v) => setState(() => _ignoreTashkeel = v),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('تجاهل النقاط'),
            value: _ignoreDots,
            onChanged: (v) => setState(() => _ignoreDots = v),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('كلمة كاملة'),
                selected: _exactWord,
                onSelected: (_) => setState(() => _exactWord = true),
              ),
              ChoiceChip(
                label: const Text('تحتوي على'),
                selected: !_exactWord,
                onSelected: (_) => setState(() => _exactWord = false),
              ),
            ],
          ),
          const Divider(),
          if (_searched)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _total == 0
                    ? 'لا توجد نتائج'
                    : 'المجموع: $_total مرة في ${_results.length} سورة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final r = _results[i];
                return ExpansionTile(
                  leading: CircleAvatar(child: Text('${r.surah.number}')),
                  title: Text(r.surah.name,
                      style: const TextStyle(fontSize: 18)),
                  trailing: Chip(label: Text('${r.count}')),
                  children: r.hits
                      .map((h) => ListTile(
                            title: Text(h.text,
                                style: const TextStyle(fontSize: 20)),
                            subtitle:
                                Text('الآية ${h.number}  •  ${h.count}×'),
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
