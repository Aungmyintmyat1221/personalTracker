import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ChecklistController.dart';
import '../theme/app_theme.dart';

class ChecklistView extends StatelessWidget {
  ChecklistView({super.key});

  final ChecklistController controller = Get.put(ChecklistController());
  final TextEditingController inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        actions: [
          IconButton(
            tooltip: 'Clear completed',
            onPressed: controller.clearDone,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Obx(() {
          final total = controller.items.length;
          final done = controller.items.where((item) => item.isDone).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: premiumCard(color: AppTheme.ink),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: Colors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$done of $total completed',
                            style: const TextStyle(color: Color(0xFFD1D5DB)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      total == 0 ? '0%' : '${((done / total) * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (controller.items.isEmpty)
                const _EmptyChecklist()
              else
                ...controller.items.map(_buildChecklistTile),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildChecklistTile(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: premiumCard(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Checkbox(
          value: item.isDone,
          onChanged: (_) => controller.toggleItem(item),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: item.isDone ? AppTheme.muted : AppTheme.ink,
            fontWeight: FontWeight.w700,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: () => controller.deleteItem(item),
          icon: const Icon(Icons.delete_outline, color: AppTheme.rose),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: inputController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Checklist item',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    await controller.addItem(inputController.text);
                    inputController.clear();
                    Get.back();
                  },
                  child: const Text('Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _EmptyChecklist extends StatelessWidget {
  const _EmptyChecklist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: premiumCard(),
      child: const Column(
        children: [
          Icon(Icons.playlist_add_check_circle_outlined, size: 42),
          SizedBox(height: 10),
          Text(
            'No checklist items yet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Add small steps you want to finish today.',
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
