import 'dart:async';

import 'package:agronavigator_app/geometry/parallel_line_generator.dart';
import 'package:agronavigator_app/models/xy_point.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:agronavigator_app/services/coordinate_convertet.dart';
import 'package:agronavigator_app/models/work_settings.dart';
import 'package:agronavigator_app/models/work_type.dart';
import 'package:agronavigator_app/map/coverage_generator.dart';
import 'package:agronavigator_app/services/hectare_calculator.dart';
import 'package:agronavigator_app/services/gps_position_filter.dart';
import 'package:agronavigator_app/services/yield_calculator.dart';
import 'package:agronavigator_app/widgets/navigation_canvas.dart';
import 'package:agronavigator_app/widgets/work_controls.dart';
import 'package:agronavigator_app/widgets/work_statistics_button.dart';
import 'package:agronavigator_app/widgets/work_statistics_panel.dart';
import 'package:agronavigator_app/widgets/work_screen/work_bottom_panel.dart';
import 'package:agronavigator_app/widgets/work_screen/work_side_panel.dart';
import 'package:agronavigator_app/widgets/work_screen/work_top_panel.dart';
import 'package:agronavigator_app/database/database_helper.dart';
import 'package:agronavigator_app/controllers/work_session_controller.dart';

class WorkPage extends StatefulWidget {
  final WorkSettings settings;
  final int? fieldId;
  const WorkPage({super.key, required this.settings, this.fieldId});

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  final WorkSessionController workSessionController = WorkSessionController();

  // Настройки работы
  double get workingWidth => widget.settings.workingWidth;
  double? get bunkerWeight => widget.settings.bunkerWeight;
  bool get isHarvest => widget.settings.workType == WorkType.harvest;
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
  late final Future<void> fieldOriginLoadFuture;
  late final Future<void> fieldCoverageLoadFuture;
  bool shouldStartNewCoverageSegment = false;
  List<XYPoint> referenceTrack = []; // Опорный проход, записанный пользователем
  List<List<XYPoint>> guidanceLines = []; // Построенные параллельные линии
  final CoverageGenerator coverage =
      CoverageGenerator(); // Генератор полигона обработанной площади
  final HectareCalculator hectareCalculator = HectareCalculator();
  late final YieldCalculator? yieldCalculator;
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

  // Рабочие расчеты еще не начались.
  bool isWorkStarted = false;
  bool isStatisticsVisible = false;
  int currentSessionNumber = 0;
  int sessionStartTrackIndex = 0;
  List<List<XYPoint>> sessionStartCoveragePolygons = [];
  List<XYPoint> sessionStartReferenceTrack = [];
  List<List<XYPoint>> sessionStartGuidanceLines = [];
  String fieldName = 'Работа без сохранения';
  double savedFieldArea = 0;

  double get totalFieldArea =>
      savedFieldArea +
      (workSessionController.isSaveConfirmed ? 0 : sessionHectares);

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
          (Position position) async {
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
            if (workSessionController.status != WorkSessionStatus.running) {
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

              await fieldOriginLoadFuture;

              isWorkStarted = true;

              if (fieldId == null) {
                origin ??= currentLatLng;
              } else if (origin == null) {
                origin = currentLatLng;
                await DatabaseHelper.instance.saveFieldOrigin(
                  fieldId!,
                  origin!.latitude,
                  origin!.longitude,
                );
              }
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

              if (isHarvest) {
                bunkerDistance += distance;
              }
              workDistance += distance;
            }

            lastRecordedPoint = currentLatLng;

            if (fieldId == null) {
              origin ??= currentLatLng;
            }

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
    yieldCalculator = isHarvest ? YieldCalculator() : null;
    fieldOriginLoadFuture = _loadFieldOrigin();
    fieldCoverageLoadFuture = _loadFieldCoverage();
    _loadFieldStatistics();
    _getLocation();
    startGpsInitialization();
  }

  Future<void> _loadFieldOrigin() async {
    if (fieldId == null) {
      return;
    }
    final savedOrigin = await DatabaseHelper.instance.getFieldOrigin(fieldId!);
    if (!mounted || savedOrigin == null) {
      return;
    }
    setState(() {
      origin = LatLng(savedOrigin['latitude']!, savedOrigin['longitude']!);
    });
  }

  Future<void> _loadFieldCoverage() async {
    if (fieldId == null) {
      return;
    }
    await fieldOriginLoadFuture;

    final workIds = await DatabaseHelper.instance.getWorkIdsForField(fieldId!);
    final allTracks = <List<XYPoint>>[];
    for (final workId in workIds) {
      final workTracks = await DatabaseHelper.instance.getWorkPoints(workId);
      allTracks.addAll(workTracks);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      coverage.loadTracks(allTracks);
      coveragePolygons = coverage.generatePolygons(workingWidth);
      hectares = coveragePolygons.fold(
        0,
        (total, polygon) => total + hectareCalculator.calculate(polygon),
      );
      sessionStartHectares = hectares;
      shouldStartNewCoverageSegment = allTracks.any(
        (segment) => segment.isNotEmpty,
      );
    });
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
    if (!workSessionController.stop()) {
      return;
    }

    final completedArea = sessionHectares;
    final completedDistance = workDistance;

    setState(() {
      isWorkStarted = false;
      isRecording = false;
    });

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить текущую сессию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (shouldSave == true) {
      if (fieldId != null) {
        final sessionTracks = coverage.tracks.sublist(sessionStartTrackIndex);
        final workId = await DatabaseHelper.instance.createWork(
          fieldId: fieldId!,
          area: completedArea,
          distance: completedDistance,
          workingWidth: workingWidth,
        );
        await DatabaseHelper.instance.saveWorkPoints(workId, sessionTracks);
        final updatedSavedArea = await DatabaseHelper.instance
            .getSavedAreaForField(fieldId!);
        if (!mounted) {
          return;
        }
        setState(() {
          savedFieldArea = updatedSavedArea;
        });
      }

      workSessionController.confirmSaved();
      workSessionController.prepareForNextSession();
      setState(() {});
      return;
    }

    setState(() {
      coverage.tracks.removeRange(
        sessionStartTrackIndex,
        coverage.tracks.length,
      );
      if (coverage.tracks.isEmpty) {
        coverage.tracks.add([]);
      }
      coveragePolygons = sessionStartCoveragePolygons
          .map((polygon) => List<XYPoint>.from(polygon))
          .toList();
      hectares = sessionStartHectares;
      workDistance = 0;
      if (isHarvest) {
        bunkerDistance = 0;
        yieldValue = 0;
      }
      referenceTrack = List<XYPoint>.from(sessionStartReferenceTrack);
      guidanceLines = sessionStartGuidanceLines
          .map((line) => List<XYPoint>.from(line))
          .toList();
      lastRecordedPoint = null;
      startMovementPoint = currentLatLng;
      workSessionController.rollbackUnsaved();
    });
  }

  Future<void> _startWork() async {
    await fieldCoverageLoadFuture;
    if (!mounted || !workSessionController.start()) {
      return;
    }
    setState(() {
      sessionStartHectares = hectares;
      sessionStartCoveragePolygons = coveragePolygons
          .map((polygon) => List<XYPoint>.from(polygon))
          .toList();
      sessionStartReferenceTrack = List<XYPoint>.from(referenceTrack);
      sessionStartGuidanceLines = guidanceLines
          .map((line) => List<XYPoint>.from(line))
          .toList();
      currentSessionNumber++;
      workDistance = 0;
      if (isHarvest) {
        bunkerDistance = 0;
        yieldValue = 0;
      }
      if (coverage.tracks.last.isNotEmpty) {
        coverage.startNewSegment();
      }
      shouldStartNewCoverageSegment = false;
      sessionStartTrackIndex = coverage.tracks.length - 1;
      lastRecordedPoint = null;
      isRecording = false;
      isWorkStarted = false;
      startMovementPoint = currentLatLng;
    });
  }

  void _pauseResumeWork() {
    final wasPaused = workSessionController.status == WorkSessionStatus.paused;
    final didChange = wasPaused
        ? workSessionController.resume()
        : workSessionController.pause();
    if (!didChange) {
      return;
    }

    setState(() {
      if (wasPaused) {
        lastRecordedPoint = currentLatLng;
        coverage.startNewSegment();
        if (currentXYPoint != null) {
          coverage.addPoint(currentXYPoint!);
        }
      }
    });
  }

  void _startReferencePass() {
    if (currentLatLng == null) {
      return;
    }
    setState(() {
      referenceTrack.clear();
      isRecording = true;
    });
  }

  void _stopReferencePass() {
    setState(() {
      isRecording = false;
      createOffsetPass();
    });
  }

  void _calculateYield() {
    final calculator = yieldCalculator;
    final weight = bunkerWeight;
    if (!isHarvest || calculator == null || weight == null) {
      return;
    }
    setState(() {
      yieldValue = calculator.calculate(
        workingWidth: workingWidth,
        distance: bunkerDistance,
        bunkerWeight: weight,
      );
      bunkerDistance = 0;
      lastRecordedPoint = currentLatLng;
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
                  workingWidth: workingWidth,
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
                      final isPaused =
                          workSessionController.status ==
                          WorkSessionStatus.paused;
                      final hasStarted =
                          workSessionController.status ==
                              WorkSessionStatus.running ||
                          isPaused;

                      return SafeArea(
                        minimum: const EdgeInsets.all(10),
                        child: Stack(
                          children: [
                            if (isPortrait) ...[
                              Align(
                                alignment: Alignment.topCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WorkBottomPanel(
                                      accuracy: gpsAccuracy,
                                      hasSignal: currentLatLng != null,
                                      compact: true,
                                    ),
                                    const SizedBox(height: 8),
                                    WorkTopPanel(
                                      area: sessionHectares,
                                      speed: gpsSpeed * 3.6,
                                      yieldValue: isHarvest ? yieldValue : null,
                                      distance: isHarvest
                                          ? bunkerDistance
                                          : workDistance,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: WorkSidePanel(
                                  onStart: _startWork,
                                  onPauseResume: _pauseResumeWork,
                                  onStop: _stopWork,
                                  onYield: isHarvest ? _calculateYield : null,
                                  isPaused: isPaused,
                                  hasStarted: hasStarted,
                                  controlsEnabled: !isGpsInitializing,
                                  compact: true,
                                ),
                              ),
                            ] else ...[
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 54,
                                    left: 54,
                                  ),
                                  child: WorkTopPanel(
                                    area: sessionHectares,
                                    speed: gpsSpeed * 3.6,
                                    yieldValue: isHarvest ? yieldValue : null,
                                    distance: isHarvest
                                        ? bunkerDistance
                                        : workDistance,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 72),
                                  child: WorkSidePanel(
                                    onStart: _startWork,
                                    onPauseResume: _pauseResumeWork,
                                    onStop: _stopWork,
                                    onYield: isHarvest ? _calculateYield : null,
                                    isPaused: isPaused,
                                    hasStarted: hasStarted,
                                    controlsEnabled: !isGpsInitializing,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: WorkBottomPanel(
                                  accuracy: gpsAccuracy,
                                  hasSignal: currentLatLng != null,
                                ),
                              ),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: WorkControls(
                                  onStart: _startReferencePass,
                                  onStop: _stopReferencePass,
                                  compact: true,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  WorkStatisticsButton(
                                    isPanelVisible: isStatisticsVisible,
                                    onPressed: () {
                                      setState(() {
                                        isStatisticsVisible =
                                            !isStatisticsVisible;
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
                                      yieldValue: isHarvest ? yieldValue : null,
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
                          ],
                        ),
                      );
                    },
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
