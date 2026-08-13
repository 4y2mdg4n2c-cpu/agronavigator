import 'package:flutter/material.dart';
import 'package:agronavigator_app/screens/work_page.dart';
import 'package:agronavigator_app/models/work_settings.dart';
import 'package:agronavigator_app/models/work_type.dart';
import 'package:agronavigator_app/database/database_helper.dart';
class HarvestPage extends StatefulWidget {
  const HarvestPage({super.key});

  @override
  State<HarvestPage> createState() => _HarvestPageState();
}

class _HarvestPageState extends State<HarvestPage> {
  final TextEditingController widthController = TextEditingController();
  final TextEditingController bunkerController = TextEditingController();
  final TextEditingController fieldNameController = TextEditingController();

  @override
  void dispose() {
    widthController.dispose();
    bunkerController.dispose();
    fieldNameController.dispose();
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
            ElevatedButton(
              onPressed: () {
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
                    ),
                  ),
                );
              },
              child: const Text('Начать работу')
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Создать поле'),
                      content: TextField(
                        controller: fieldNameController,
                        decoration: const InputDecoration(
                          labelText: 'Название поля',
                          border: OutlineInputBorder(),
                        )
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await DatabaseHelper.instance.createField(
                              fieldNameController.text,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Создать'),
                        )
                      ]
                    );
                  },
                );
              },
              child: const Text('Создать поле')
            ),
            const SizedBox(height: 15),
            
            
          ],
        ),
      ),
    );
  }
}