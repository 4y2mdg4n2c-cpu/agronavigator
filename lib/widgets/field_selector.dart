import 'package:flutter/material.dart';
import 'package:agronavigator_app/database/database_helper.dart';

class FieldSelector extends StatefulWidget {
  final ValueChanged<int?> onFieldSelected;
  const FieldSelector({super.key, required this.onFieldSelected});

  @override
  State<FieldSelector> createState() => _FieldSelectorState();
}

class _FieldSelectorState extends State<FieldSelector> {
  List<Map<String, dynamic>> fields = []; // Список полей из базы данных
  int?
  selectedFieldId; // id выбранного поля, null означает, что поле не выбрано
  final TextEditingController fieldNameController = TextEditingController();
  @override
  void dispose() {
    fieldNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadFields(); // Загружаем поля при инициализации виджета
  }

  Future<void> _loadFields() async {
    // Загружает поля из SQLite и обновляет интерфейс.
    final loadedFields = await DatabaseHelper.instance.getFields();
    setState(() {
      fields = loadedFields;
    });
  }

  Future<void> _showAddFieldDialog() async {
    // Показывает окно для создания нового поля
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать поле'),
          content: TextField(
            controller: fieldNameController,
            decoration: const InputDecoration(
              labelText: 'Название поля',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.createField(
                  fieldNameController.text,
                );
                fieldNameController.clear(); // Очищаем поле ввода
                Navigator.pop(context);
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
    await _loadFields(); // Обновляем список полей после создания нового
  }
  Future<void> _showDeleteFieldDialog() async { // Показывает окно для удаления поля
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить поле?'),
          content: const Text('Вы уверены, что хотите удалить  поле?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.deleteField(
                  selectedFieldId!,
                );
                await _loadFields();
                selectedFieldId = null;
                widget.onFieldSelected(null);

                Navigator.pop(context);
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int?>(
              value: selectedFieldId,
              hint: const Text('Поле не выбрано'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Поле не выбрано'),
                ),
                ...fields.map(
                  (field) => DropdownMenuItem<int?>(
                    value: field['id'],
                    child: Text(field['name'] as String),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedFieldId = value;
                });
                widget.onFieldSelected(
                  value,
                ); // Вызываем callback при выборе поля
              },
            ),
            if (selectedFieldId != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showDeleteFieldDialog,
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
              ),
            ]
          ],
        ),
        ElevatedButton(
          onPressed: _showAddFieldDialog,
          child: const Text('Создать поле'),
        ),
      ],
    );
  }
}
