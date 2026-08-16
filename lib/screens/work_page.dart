import 'dart:async';

import 'package:agronavigator_app/geometry/parallel_line_generator.dart';
import 'package:agronavigator_app/models/xy_point.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:agronavigator_app/services/coordinate_convertet.dart';
import 'package:agronavigator_app/models/work_settings.dart';
import 'package:agronavigator_app/map/coverage_generator.dart';
import 'package:agronavigator_app/services/hectare_calculator.dart';
import 'package:agronavigator_app/services/gps_position_filter.dart';
import 'package:agronavigator_app/widgets/info_bar.dart';
import 'package:agronavigator_app/widgets/work_controls.dart';
import 'package:agronavigator_app/services/yield_calculator.dart';
import 'package:agronavigator_app/widgets/navigation_canvas.dart';
import 'package:agronavigator_app/widgets/gps_signal_indicator.dart';
import 'package:agronavigator_app/widgets/work_action_buttons.dart';
import 'package:agronavigator_app/widgets/work_statistics_button.dart';
import 'package:agronavigator_app/widgets/work_statistics_panel.dart';
import 'package:agronavigator_app/database/database_helper.dart';

class WorkPage extends StatefulWidget {
  final WorkSettings settings;
  final int? fieldId;
  const WorkPage({super.key, required this.settings, this.fieldId});

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  // Настройки работы
  double get workingWidth => widget.settings.workingWidth;
  double? get bunkerWeight => widget.settings.bunkerWeight;
  int? get fieldId => widget.fieldId;
  // GPS
  LatLng? currentLatLng; // Последняя полученная GPS точка
  LatLng? lastRecordedPoint; // Последняя координата, записанная в рабочий трек
  XYPoint?
  currentXYPoint; // Текущее положение трактора в локальной системе координат
  bool isRecording =
      false; // Запись опорной траектории для построения направляющих
  // НАВИГАЦИЯ
  // Начало локальной системы координат
  // Устанавливается один раз после начала работы и больше не изменяется
  LatLng? origin;
  List<XYPoint> referenceTrack = []; // Опорный проход, записанный пользователем
  List<List<XYPoint>> guidanceLines = []; // Построенные параллельные линии
  final CoverageGenerator coverage =
      CoverageGenerator(); // Генератор полигона обработанной площади
  final HectareCalculator hectareCalculator = HectareCalculator();
  final YieldCalculator yieldCalculator = YieldCalculator();
  final GpsPositionFilter gpsPositionFilter = GpsPositionFilter();
  List<List<XYPoint>> coveragePolygons = []; // Полигоны обработанной площади
  double hectares = 0; // Рассчитанная площадь в гектарах
  double sessionStartHectares = 0; // Площадь на момент последнего старта
  double get sessionHectares => hectares - sessionStartHectares;
  double gpsAccuracy = 0;
  double gpsSpeed = 0;
  double gpsHeading = -1;

  // Минимальное время ожидания прошло.
  bool gpsDelayFinished = false;

  // Расстояние, пройденное с начала заполнения бункера.
  double bunkerDistance = 0;
  double workDistance = 0; // Общее расстояние за день (не обнуляется)

  // Текущая урожайность, ц/га.
  double yieldValue = 0;

  // Идет подготовка GPS.
  bool isGpsInitializing = true;

  // Работа еще не началась.
  bool isWorkStarted = false;
  // Пользователь нажал кнопку "Старт"
  bool hasStarted = false;
  // Работа временно приостановлена.
  bool isPaused = false;
  // Работа завершена кнопкой "Стоп"
  bool isWorkFinished = false;
  bool isStatisticsVisible = false;
  bool isCurrentSessionSaved = false;
  int currentSessionNumber = 0;
  String fieldName = 'Работа без сохранения';
  double savedFieldArea = 0;

  double get totalFieldArea =>
      savedFieldArea + (isCurrentSessionSaved ? 0 : sessionHectares);

  // Точка начала движения после подготовки GPS.
  LatLng? startMovementPoint;

  // Обратный отсчет подготовки GPS.
  int gpsCountdown = 10;
  StreamSubscription<Position>? positionSubscription;
  // Основной цикл навигации
  // 1. Получение GPS.
  // 2. Проверка точности.
  // 3. Ожидание подготовки GPS.
  // 4. Ожидание первых 10 метров движения.
  // 5. Перевод GPS в XY.
  // 6. Построение полигона.
  // 7. Расчет площади.
  // 8. При записи прохода
  //    сохранение referenceTrack.
  Future<void> _getLocation() async {
    await Geolocator.requestPermission();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final filteredPosition = gpsPositionFilter.filter(position);

            // Обновляем данные GPS
            setState(() {
              gpsAccuracy = position.accuracy;
              gpsSpeed = position.speed;
              gpsHeading = position.heading;
              if (filteredPosition != null) {
                currentLatLng = LatLng(
                  filteredPosition.latitude,
                  filteredPosition.longitude,
                );
              }
            });

            if (filteredPosition == null) {
              return;
            }

            final acceptedPosition = filteredPosition;

            if (origin != null) {
              final currentPoint = CoordinateConverter.latLngToXY(
                currentLatLng!,
                origin!,
              );
              setState(() {
                currentXYPoint = currentPoint;
              });
            }

            // Во время подготовки GPS:
            // - показываем положение на карте;
            // - НЕ считаем площадь;
            // - НЕ считаем расстояние;
            // - НЕ записываем трек.
            if (isGpsInitializing) {
              // Минимум 10 секунд прошло
              // и точность стала достаточной.
              if (gpsDelayFinished && position.accuracy <= 10) {
                setState(() {
                  isGpsInitializing = false;
                });
                startMovementPoint = null;

                print('GPS готов');
              }

              return;
            }
            if (!hasStarted) {
              return;
            }
            if (isPaused) {
              return;
            }
            // Ждем первые 10 метров движения.
            if (!isWorkStarted) {
              startMovementPoint ??= currentLatLng;

              final startDistance = Geolocator.distanceBetween(
                startMovementPoint!.latitude,
                startMovementPoint!.longitude,
                currentLatLng!.latitude,
                currentLatLng!.longitude,
              );

              if (startDistance < 10) {
                return;
              }

              isWorkStarted = true;

              origin = currentLatLng;
              lastRecordedPoint = currentLatLng;

              print('Работа началась');
            }

            final minDistance = workingWidth * 0.5;

            if (lastRecordedPoint != null) {
              final distance = Geolocator.distanceBetween(
                lastRecordedPoint!.latitude,
                lastRecordedPoint!.longitude,
                acceptedPosition.latitude,
                acceptedPosition.longitude,
              );

              if (distance < minDistance) {
                return;
              }

              bunkerDistance += distance;
              workDistance += distance;
            }

            lastRecordedPoint = currentLatLng;

            origin ??= currentLatLng;

            final xyPoint = CoordinateConverter.latLngToXY(
              currentLatLng!,
              origin!,
            );

            setState(() {
              currentXYPoint = xyPoint;
              coverage.addPoint(xyPoint);

              coveragePolygons = coverage.generatePolygons(workingWidth);

              hectares = coveragePolygons.fold(
                0,
                (total, polygon) =>
                    total + hectareCalculator.calculate(polygon),
              );

              if (isRecording) {
                referenceTrack.add(xyPoint);
              }
            });
          },
        );
  }

  @override
  void initState() {
    super.initState();
    _loadFieldStatistics();
    _getLocation();
    startGpsInitialization();
  }

  Future<void> _loadFieldStatistics() async {
    if (fieldId == null) {
      return;
    }
    final results = await Future.wait([
      DatabaseHelper.instance.getFieldName(fieldId!),
      DatabaseHelper.instance.getSavedAreaForField(fieldId!),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      fieldName = results[0] as String? ?? 'Поле не найдено';
      savedFieldArea = results[1] as double;
    });
  }

  void startGpsInitialization() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (gpsCountdown > 0) {
        setState(() {
          gpsCountdown--;
        });
      }
      if (gpsCountdown <= 0) {
        gpsDelayFinished = true;
        timer.cancel();
      }
    });
  }

  Future<void> _stopWork() async {
    final completedArea = sessionHectares;
    final completedDistance = workDistance;
    final stoppedSessionNumber = currentSessionNumber;

    setState(() {
      isWorkFinished = true;
      hasStarted = false;
      isPaused = false;
      isWorkStarted = false;
      isRecording = false;
    });

    if (fieldId != null) {
      await DatabaseHelper.instance.createWork(
        fieldId: fieldId!,
        area: completedArea,
        distance: completedDistance,
        workingWidth: workingWidth,
      );
      final updatedSavedArea = await DatabaseHelper.instance
          .getSavedAreaForField(fieldId!);
      if (mounted) {
        setState(() {
          savedFieldArea = updatedSavedArea;
          if (currentSessionNumber == stoppedSessionNumber) {
            isCurrentSessionSaved = true;
          }
        });
      }
    }
  }

  void _startWork() {
    setState(() {
      sessionStartHectares = hectares;
      isCurrentSessionSaved = false;
      currentSessionNumber++;
      if (isWorkFinished) {
        workDistance = 0;
        bunkerDistance = 0;
        yieldValue = 0;
        coverage.startNewSegment();
        lastRecordedPoint = null;
        isRecording = false;
        isWorkFinished = false;
      }
      hasStarted = true;
      isPaused = false;
      isWorkStarted = false;
      startMovementPoint = currentLatLng;
    });
  }

  void _pauseResumeWork() {
    setState(() {
      if (isPaused) {
        isPaused = false;
        lastRecordedPoint = currentLatLng;
        coverage.startNewSegment();
        if (currentXYPoint != null) {
          coverage.addPoint(currentXYPoint!);
        }
      } else {
        isPaused = true;
      }
    });
  }

  // Основной экран навигации.
  // Содержит:
  // - рабочую область;
  // - экран инициализации GPS;
  // - информационную панель;
  // - кнопки управления.
  @override
  Widget build(BuildContext context) {
    final infoBar = InfoBar(
      area: sessionHectares,
      speed: gpsSpeed * 3.6,
      gpsAccuracy: gpsAccuracy,
      yieldValue: yieldValue,
      distance: bunkerDistance,
    );
    final controls = WorkControls(
      onStart: () {
        if (currentLatLng != null) {
          setState(() {
            referenceTrack.clear();
            isRecording = true;
          });
        }
      },
      onStop: () {
        setState(() {
          isRecording = false;
          createOffsetPass();
        });
      },
      onBunker: () {
        if (bunkerWeight == null) {
          return;
        }
        setState(() {
          yieldValue = yieldCalculator.calculate(
            workingWidth: workingWidth,
            distance: bunkerDistance,
            bunkerWeight: bunkerWeight!,
          );
          bunkerDistance = 0;
          lastRecordedPoint = currentLatLng;
        });
      },
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                NavigationCanvas(
                  firstPass: referenceTrack,
                  guidanceLines: guidanceLines,
                  coveragePolygons: coveragePolygons,
                  currentPoint: currentXYPoint,
                  gpsHeading: gpsHeading,
                  rotateWithGpsHeading: true,
                ),

                if (isGpsInitializing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.gps_fixed,
                              color: Colors.white,
                              size: 60,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Инициализация навигации',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Подождите... $gpsCountdown',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      final isPortrait = orientation == Orientation.portrait;

                      return SafeArea(
                        minimum: EdgeInsets.fromLTRB(
                          8,
                          8,
                          isPortrait ? 8 : 16,
                          isPortrait ? 8 : 20,
                        ),
                        child: isPortrait
                            ? Align(
                                alignment: Alignment.topLeft,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InfoBar(
                                        area: sessionHectares,
                                        speed: gpsSpeed * 3.6,
                                        gpsAccuracy: gpsAccuracy,
                                        yieldValue: yieldValue,
                                        distance: bunkerDistance,
                                        compact: true,
                                      ),
                                      const SizedBox(height: 6),
                                      WorkControls(
                                        onStart: controls.onStart,
                                        onStop: controls.onStop,
                                        onBunker: controls.onBunker,
                                        compact: true,
                                      ),
                                      const SizedBox(height: 6),
                                      if (!isGpsInitializing)
                                        WorkActionButtons(
                                          onStart: _startWork,
                                          onPauseResume: _pauseResumeWork,
                                          onStop: _stopWork,
                                          isPaused: isPaused,
                                          hasStarted: hasStarted,
                                        ),
                                      const SizedBox(height: 10),
                                      GpsSignalIndicator(
                                        accuracy: gpsAccuracy,
                                        hasSignal: currentLatLng != null,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: infoBar,
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        right: 12,
                                      ),
                                      child: GpsSignalIndicator(
                                        accuracy: gpsAccuracy,
                                        hasSignal: currentLatLng != null,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: controls,
                                  ),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: !isGpsInitializing
                                        ? WorkActionButtons(
                                            onStart: _startWork,
                                            onPauseResume: _pauseResumeWork,
                                            onStop: _stopWork,
                                            isPaused: isPaused,
                                            hasStarted: hasStarted,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top:
                            MediaQuery.orientationOf(context) ==
                                Orientation.landscape
                            ? 64
                            : 8,
                        right: 8,
                        left: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          WorkStatisticsButton(
                            isPanelVisible: isStatisticsVisible,
                            onPressed: () {
                              setState(() {
                                isStatisticsVisible = !isStatisticsVisible;
                              });
                            },
                          ),
                          if (isStatisticsVisible) ...[
                            const SizedBox(height: 6),
                            WorkStatisticsPanel(
                              fieldName: fieldName,
                              sessionArea: sessionHectares,
                              totalFieldArea: totalFieldArea,
                              sessionDistance: workDistance,
                              workingWidth: workingWidth,
                              yieldValue: yieldValue,
                              onClose: () {
                                setState(() {
                                  isStatisticsVisible = false;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Строит параллельные направляющие
  // по записанному referenceTrack.
  //
  // Не изменяет:
  // - GPS-трек;
  // - площадь;
  // - полигон;
  // - расстояние.
  void createOffsetPass() {
    guidanceLines.clear();

    for (int i = 1; i <= 100; i++) {
      guidanceLines.add(
        ParallelLineGenerator.generate(referenceTrack, workingWidth * i),
      );

      guidanceLines.add(
        ParallelLineGenerator.generate(referenceTrack, -workingWidth * i),
      );
    }
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }
}
