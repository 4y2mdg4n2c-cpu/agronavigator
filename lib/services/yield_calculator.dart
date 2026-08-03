/// Выполняет расчет урожайности.
///
/// Урожайность рассчитывается по:
/// - ширине захвата жатки;
/// - расстоянию, пройденному до заполнения бункера;
/// - массе полного бункера.
///
/// Результат возвращается в центнерах на гектар (ц/га).
class YieldCalculator {

  /// Возвращает урожайность в ц/га.
  double calculate({
    required double workingWidth,
    required double distance,
    required double bunkerWeight,
  }) {
    // Площадь в гектарах
    final area = (workingWidth * distance) / 10000;

    // Защита от деления на ноль
    if (area == 0) {
      return 0;
    }

    // Урожайность в ц/га
    return (bunkerWeight / area) / 100;
  }
}