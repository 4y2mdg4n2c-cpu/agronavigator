import 'package:flutter/material.dart';
import 'package:agronavigator_app/screens/harvest_page.dart';
import 'package:agronavigator_app/screens/soil_page.dart';
import 'package:agronavigator_app/map/map_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Агронавигатор'),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Выберите режим работы: ',
              style: TextStyle(fontSize: 18),
            ),
          
          
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HarvestPage()),
                );
              },
              child: Text('Уборка урожая')
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SoilPage()),
                );
              },
              child: Text('Почвообработка'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Карта'),
             ),
            ),
          ]
        ),
      ),
    );
  }
}