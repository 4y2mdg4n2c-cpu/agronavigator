import 'package:agronavigator_app/models/work_type.dart';

class WorkSettings {
  final WorkType workType;
  final double workingWidth;
  final double? bunkerWeight;

  const WorkSettings({
    required this.workType,
    required this.workingWidth,
    this.bunkerWeight,
  });
}