import 'package:flutter/material.dart';
import 'package:agronavigator_app/screens/work_page.dart';
import 'package:agronavigator_app/models/work_settings.dart';
import 'package:agronavigator_app/models/work_type.dart';
import 'package:agronavigator_app/widgets/field_selector.dart';
class HarvestPage extends StatefulWidget {
  const HarvestPage({super.key});

  @override
  State<HarvestPage> createState() => _HarvestPageState();
}

class _HarvestPageState extends State<HarvestPage> {
  final TextEditingController widthController = TextEditingController();
  final TextEditingController bunkerController = TextEditingController();
  int? selectedFieldId;

  @override
  void dispose() {
    widthController.dispose();
    bunkerController.dispose();
    super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уборка урожая'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Режим уборки урожая',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),
            Text('Ширина жатки (м):'),
            SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: TextField(
                controller: widthController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 25),
            Text('Масса полного бункера (кг): '),
            SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: TextField(
                controller: bunkerController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                )
              )
            ),
            const SizedBox(height: 25),
            FieldSelector(
              onFieldSelected: (fieldId) {
                setState(() {
                  selectedFieldId = fieldId;
                });
              }
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                if (selectedFieldId == null) {
                  final shouldContinue = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Работа без сохранения'),
                        content: const Text(
                          'Вы начинаете работу без сохранения данных. '
                          'Чтобы данные сохранялись, создайте новое поле '
                          'или выберите существующее.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Назад'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text('Продолжить'),
                          ),
                        ],
                      );
                    },
                  );
                  if (shouldContinue != true) {
                    return;
                  }
                }
                final settings = WorkSettings(
                  workType: WorkType.harvest,
                  workingWidth: double.parse(widthController.text),
                  bunkerWeight: double.parse(bunkerController.text)
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkPage(
                      settings: settings,
                      fieldId: selectedFieldId,
                    ),
                  ),
                );
              },
              child: const Text('Начать работу')
            ), 
          ],
        ),
      ),
    );
  }
}