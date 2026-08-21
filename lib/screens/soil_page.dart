import 'package:flutter/material.dart';
import 'package:agronavigator_app/screens/work_page.dart';
import 'package:agronavigator_app/models/work_settings.dart';
import 'package:agronavigator_app/models/work_type.dart';
import 'package:agronavigator_app/widgets/field_selector.dart';

class SoilPage extends StatefulWidget {
  const SoilPage({super.key});

  @override
  State<SoilPage> createState() => _SoilPageState();
}

class _SoilPageState extends State<SoilPage> {
  final TextEditingController widthController = TextEditingController();
  int? selectedFieldId;

  @override
  void dispose() {
    widthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Почвообработка')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Режим почвообработки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),
            Text('Ширина агрегата (м): '),
            SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: TextField(
                controller: widthController,

                textAlign: TextAlign.center,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 25),
            FieldSelector(
              onFieldSelected: (fieldId) {
                setState(() {
                  selectedFieldId = fieldId;
                });
              },
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                final settings = WorkSettings(
                  workType: WorkType.soil,
                  workingWidth: double.parse(widthController.text),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkPage(settings: settings, fieldId: selectedFieldId),
                  ),
                );
              },
              child: Text('Начать работу'),
            ),
          ],
        ),
      ),
    );
  }
}
