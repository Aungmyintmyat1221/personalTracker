import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import '../models/routineModel.dart';
import '../models/taskModel.dart';
import '../models/transactionModel.dart';

class GroqAiService {
  static const _apiKeyKey = 'groq_api_key';
  static const _storage = FlutterSecureStorage();
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static Future<String?> readApiKey() {
    return _storage.read(key: _apiKeyKey);
  }

  static Future<void> saveApiKey(String apiKey) {
    return _storage.write(key: _apiKeyKey, value: apiKey);
  }

  static Future<void> clearApiKey() {
    return _storage.delete(key: _apiKeyKey);
  }

  static Future<String> ask(
    String message, {
    AiAnswerMode mode = AiAnswerMode.tracker,
  }) async {
    final apiKey = await readApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const GroqAiException('Add your Groq API key first.');
    }

    final context = switch (mode) {
      AiAnswerMode.tracker => _trackerContext(),
      AiAnswerMode.global => await _globalContext(message),
      AiAnswerMode.english => _englishContext(),
    };

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer ${apiKey.trim()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': switch (mode) {
              AiAnswerMode.tracker =>
                'You are a concise personal tracker assistant. Give practical advice using the provided app data. Keep answers short, warm, and actionable.',
              AiAnswerMode.global =>
                'You are a concise global assistant. Answer general questions clearly. If live context is provided, use it and mention that it is based on the fetched context. If no live context is provided for a current-events question, say that you may not have live data.',
              AiAnswerMode.english =>
                'You are an English speaking coach for a Myanmar learner. Teach practical spoken English. Use simple explanations, natural examples, short drills, and gentle corrections. Keep lessons readable on a phone.',
            },
          },
          {'role': 'user', 'content': '$context\n\nUser request: $message'},
        ],
        'max_completion_tokens': 500,
        'temperature': 0.7,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] as Map<String, dynamic>?;
      throw GroqAiException(
        error?['message'] as String? ?? 'Groq request failed.',
      );
    }

    final choices = body['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }

    throw const GroqAiException('Groq returned an empty response.');
  }

  static String _trackerContext() {
    final now = DateTime.now();
    final tasks = Hive.box<TaskModel>('tasks').values.toList();
    final routines = Hive.box<RoutineModel>('routines').values.toList();
    final transactions = Hive.box<TransactionModel>(
      'transactions',
    ).values.toList();
    final pendingTasks = tasks.where((task) => !task.isDone).toList();
    final nextRoutine = _nextRoutine(routines, now);
    final balance = transactions.fold<double>(0, (sum, tx) {
      return tx.type == 'income' ? sum + tx.amount : sum - tx.amount;
    });
    final monthStart = DateTime(now.year, now.month);
    final monthTransactions = transactions.where(
      (tx) => !tx.date.isBefore(monthStart),
    );
    final monthlyIncome = monthTransactions
        .where((tx) => tx.type == 'income')
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final monthlyExpense = monthTransactions
        .where((tx) => tx.type == 'expense')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return [
      'Tracker snapshot:',
      'Pending tasks: ${pendingTasks.map((task) => '${task.title} (${task.priority})').take(8).join(', ').ifEmpty('none')}',
      'Next routine: ${nextRoutine == null ? 'none' : '${nextRoutine.title} at ${DateFormat('h:mm a').format(DateTime(0, 1, 1, nextRoutine.hour, nextRoutine.minute))}'}',
      'Money balance: ${balance.toStringAsFixed(0)}',
      'This month income: ${monthlyIncome.toStringAsFixed(0)}',
      'This month expense: ${monthlyExpense.toStringAsFixed(0)}',
    ].join('\n');
  }

  static Future<String> _globalContext(String message) async {
    final lower = message.toLowerCase();
    final sections = <String>[];

    if (_looksLikeCryptoQuestion(lower)) {
      final cryptoContext = await _cryptoContext();
      if (cryptoContext.isNotEmpty) sections.add(cryptoContext);
    }

    if (_looksLikeCurrentQuestion(lower)) {
      final newsContext = await _newsContext(message);
      if (newsContext.isNotEmpty) sections.add(newsContext);
    }

    if (sections.isEmpty) {
      return 'Global mode: no live web context was fetched for this question.';
    }

    return sections.join('\n\n');
  }

  static String _englishContext() {
    return [
      'English speaking mode:',
      'Give one focused speaking lesson or practice session.',
      'Prefer this structure when useful: Goal, Useful phrases, Mini dialogue, Practice prompts, Common mistake, Homework.',
      'If the user writes English, correct it kindly and explain the natural version.',
      'If the user asks for speaking practice, act as a conversation partner and ask one question at a time.',
    ].join('\n');
  }

  static bool _looksLikeCryptoQuestion(String lower) {
    return lower.contains('crypto') ||
        lower.contains('bitcoin') ||
        lower.contains('btc') ||
        lower.contains('ethereum') ||
        lower.contains('eth') ||
        lower.contains('coin');
  }

  static bool _looksLikeCurrentQuestion(String lower) {
    return lower.contains('today') ||
        lower.contains('latest') ||
        lower.contains('current') ||
        lower.contains('news') ||
        lower.contains('market') ||
        lower.contains('price');
  }

  static Future<String> _cryptoContext() async {
    try {
      final uri = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price'
        '?ids=bitcoin,ethereum,solana,binancecoin,ripple,dogecoin,cardano'
        '&vs_currencies=usd&include_24hr_change=true',
      );
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) return '';

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final names = {
        'bitcoin': 'Bitcoin',
        'ethereum': 'Ethereum',
        'solana': 'Solana',
        'binancecoin': 'BNB',
        'ripple': 'XRP',
        'dogecoin': 'Dogecoin',
        'cardano': 'Cardano',
      };

      final lines = names.entries.map((entry) {
        final coin = data[entry.key] as Map<String, dynamic>?;
        if (coin == null) return null;
        final price = (coin['usd'] as num?)?.toDouble();
        final change = (coin['usd_24h_change'] as num?)?.toDouble();
        if (price == null) return null;
        final changeText = change == null
            ? '24h change unavailable'
            : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}% 24h';
        return '${entry.value}: \$${price.toStringAsFixed(price >= 100 ? 0 : 2)} ($changeText)';
      }).whereType<String>();

      return 'Live crypto price context from CoinGecko:\n${lines.join('\n')}';
    } catch (_) {
      return '';
    }
  }

  static Future<String> _newsContext(String query) async {
    try {
      final uri = Uri.https('news.google.com', '/rss/search', {
        'q': query,
        'hl': 'en-US',
        'gl': 'US',
        'ceid': 'US:en',
      });
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) return '';

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item').take(5).map((item) {
        final title = item.getElement('title')?.innerText.trim();
        final source = item.getElement('source')?.innerText.trim();
        final date = item.getElement('pubDate')?.innerText.trim();
        if (title == null || title.isEmpty) return null;
        return '- $title${source == null || source.isEmpty ? '' : ' ($source)'}${date == null || date.isEmpty ? '' : ' - $date'}';
      }).whereType<String>();

      final headlines = items.join('\n');
      if (headlines.isEmpty) return '';
      return 'Live news headline context from Google News RSS:\n$headlines';
    } catch (_) {
      return '';
    }
  }

  static RoutineModel? _nextRoutine(List<RoutineModel> routines, DateTime now) {
    final upcoming = routines
        .where((routine) => !routine.isDoneToday)
        .map((routine) => MapEntry(routine, _nextRoutineDate(routine, now)))
        .where((entry) => entry.value != null)
        .toList();

    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.value!.compareTo(b.value!));
    return upcoming.first.key;
  }

  static DateTime? _nextRoutineDate(RoutineModel routine, DateTime from) {
    for (var offset = 0; offset < 14; offset++) {
      final day = from.add(Duration(days: offset));
      if (!_matchesSchedule(routine, day)) continue;
      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        routine.hour,
        routine.minute,
      );
      if (candidate.isAfter(from)) return candidate;
    }
    return null;
  }

  static bool _matchesSchedule(RoutineModel routine, DateTime day) {
    final workdays = _workdays();
    switch (routine.scheduleType) {
      case 'workday':
        return workdays.contains(day.weekday);
      case 'holiday':
        return !workdays.contains(day.weekday);
      default:
        return true;
    }
  }

  static List<int> _workdays() {
    final saved = Hive.box('app_meta').get('routine_workdays');
    if (saved is List) return saved.whereType<int>().toList();
    return const [1, 2, 3, 4, 5];
  }
}

enum AiAnswerMode { tracker, global, english }

class GroqAiException implements Exception {
  final String message;

  const GroqAiException(this.message);

  @override
  String toString() => message;
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
