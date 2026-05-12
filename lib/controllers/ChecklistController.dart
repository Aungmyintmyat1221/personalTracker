import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ChecklistItem {
  final int key;
  final String title;
  final bool isDone;

  ChecklistItem({
    required this.key,
    required this.title,
    required this.isDone,
  });

  ChecklistItem copyWith({String? title, bool? isDone}) {
    return ChecklistItem(
      key: key,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

class ChecklistController extends GetxController {
  final items = <ChecklistItem>[].obs;
  late Box checklistBox;

  @override
  void onInit() {
    super.onInit();
    checklistBox = Hive.box('checklist');
    loadItems();
  }

  void loadItems() {
    items.value = checklistBox.keys.map((key) {
      final raw = Map<String, dynamic>.from(checklistBox.get(key) as Map);
      return ChecklistItem(
        key: key as int,
        title: raw['title'] as String,
        isDone: raw['isDone'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> addItem(String title) async {
    final text = title.trim();
    if (text.isEmpty) return;

    await checklistBox.add({
      'title': text,
      'isDone': false,
    });
    loadItems();
  }

  Future<void> toggleItem(ChecklistItem item) async {
    await checklistBox.put(item.key, {
      'title': item.title,
      'isDone': !item.isDone,
    });
    loadItems();
  }

  Future<void> deleteItem(ChecklistItem item) async {
    await checklistBox.delete(item.key);
    loadItems();
  }

  Future<void> clearDone() async {
    final doneKeys = items.where((item) => item.isDone).map((item) => item.key);
    await checklistBox.deleteAll(doneKeys);
    loadItems();
  }
}
