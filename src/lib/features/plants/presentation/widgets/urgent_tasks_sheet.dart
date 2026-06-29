import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/urgent_plant_task.dart';
import '../providers/plant_providers.dart';
import '../providers/urgent_tasks_provider.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

// HARDCODE(demo): tareas derivadas de plantas locales; marcar check actualiza estado en memoria.
// TODO(backend): PATCH tarea completada y sincronizar con backend.
void showUrgentTasksSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const UrgentTasksSheet(),
  );
}

class UrgentTasksSheet extends ConsumerStatefulWidget {
  const UrgentTasksSheet({super.key});

  @override
  ConsumerState<UrgentTasksSheet> createState() => _UrgentTasksSheetState();
}

class _UrgentTasksSheetState extends ConsumerState<UrgentTasksSheet> {
  final Set<String> _completingIds = {};

  void _onTaskChecked(UrgentPlantTask task, bool? checked) {
    if (checked != true || _completingIds.contains(task.id)) return;

    setState(() => _completingIds.add(task.id));
    ref.read(plantsProvider.notifier).completeUrgentTask(task);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(urgentTasksProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GardenBottomSheetContainer(
      margin: const EdgeInsets.only(top: 48),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GardenColors.dustLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: GardenColors.creamPaper),
                    ),
                    child: const GardenIcon(
                      asset: GardenIcons.notification,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acciones urgentes',
                          style: GardenTextStyles.title.copyWith(
                            color: GardenColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Marca lo que ya hiciste por planta',
                          style: GardenTextStyles.bodySmall.copyWith(
                            color: GardenColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: GardenColors.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tasks.isEmpty)
                _EmptyState()
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final isDone = _completingIds.contains(task.id);

                      return _TaskTile(
                        task: task,
                        isDone: isDone,
                        onChanged: (checked) => _onTaskChecked(task, checked),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Column(
        children: [
          const GardenIcon(asset: GardenIcons.plantEco, size: 40),
          const SizedBox(height: 12),
          Text(
            '¡Todo al día!',
            style: GardenTextStyles.title.copyWith(
              color: GardenColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay acciones urgentes pendientes.',
            textAlign: TextAlign.center,
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final UrgentPlantTask task;
  final bool isDone;
  final ValueChanged<bool?> onChanged;

  const _TaskTile({
    required this.task,
    required this.isDone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isDone ? 0.45 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GardenColors.dustLight),
          boxShadow: [
            BoxShadow(
              color: GardenColors.ink.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CheckboxListTile(
          value: isDone,
          onChanged: isDone ? null : onChanged,
          activeColor: GardenColors.leafDark,
          checkColor: Colors.white,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GardenColors.creamLight,
                  shape: BoxShape.circle,
                ),
                child: GardenIcon(asset: task.iconAsset, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.ink,
                    fontWeight: FontWeight.w700,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                task.plantName,
                style: GardenTextStyles.label.copyWith(
                  color: GardenColors.leafDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                task.description,
                style: GardenTextStyles.bodySmall.copyWith(
                  color: GardenColors.inkSoft,
                  fontSize: 12,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
