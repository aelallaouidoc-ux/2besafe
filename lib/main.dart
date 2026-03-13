import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'services/ai_service.dart';

void main() {
  runApp(const BeSafeApp());
}

class BeSafeApp extends StatelessWidget {
  const BeSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7A00)),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const MainScreen(),
    );
  }
}

class WorkerVitals {
  final String workerName;
  final int heartRate;
  final int spo2;
  final double temperature;
  final int systolic;
  final int diastolic;
  final double riskScore;
  final String status;
  final List<double> hrHistory;
  final List<double> tempHistory;
  final List<double> spo2History;
  final String zone;
  final bool online;

  const WorkerVitals({
    required this.workerName,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.systolic,
    required this.diastolic,
    required this.riskScore,
    required this.status,
    required this.hrHistory,
    required this.tempHistory,
    required this.spo2History,
    required this.zone,
    required this.online,
  });

  String get bloodPressure => '$systolic / $diastolic';

  WorkerVitals copyWith({
    String? workerName,
    int? heartRate,
    int? spo2,
    double? temperature,
    int? systolic,
    int? diastolic,
    double? riskScore,
    String? status,
    List<double>? hrHistory,
    List<double>? tempHistory,
    List<double>? spo2History,
    String? zone,
    bool? online,
  }) {
    return WorkerVitals(
      workerName: workerName ?? this.workerName,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      riskScore: riskScore ?? this.riskScore,
      status: status ?? this.status,
      hrHistory: hrHistory ?? this.hrHistory,
      tempHistory: tempHistory ?? this.tempHistory,
      spo2History: spo2History ?? this.spo2History,
      zone: zone ?? this.zone,
      online: online ?? this.online,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Random random = Random();
  final AiService aiService = AiService();

  Timer? timer;
  int selectedIndex = 0;
  int selectedWorkerIndex = 0;

  String aiModelStatus = 'AI model not initialized';
  String aiPredictionLabel = 'No prediction yet';
  double aiStressProbability = 0.0;
  double aiBaselineProbability = 0.0;
  bool isAiLoading = false;

  // IMPORTANT:
  // Replace 44 with the real number of features used to train your model.
  static const int modelFeatureCount = 44;

  late List<WorkerVitals> workers = [
    createWorker(
      name: 'Worker A',
      zone: 'Construction Zone A',
      hr: 96,
      spo2: 98,
      temp: 37.3,
      sys: 118,
      dia: 77,
    ),
    createWorker(
      name: 'Worker B',
      zone: 'Confined Space B',
      hr: 112,
      spo2: 95,
      temp: 38.1,
      sys: 103,
      dia: 68,
    ),
    createWorker(
      name: 'Worker C',
      zone: 'Solar Plant Sector',
      hr: 88,
      spo2: 97,
      temp: 37.0,
      sys: 121,
      dia: 80,
    ),
    createWorker(
      name: 'Worker D',
      zone: 'Maintenance Tunnel',
      hr: 124,
      spo2: 92,
      temp: 38.6,
      sys: 96,
      dia: 64,
    ),
  ];

  WorkerVitals createWorker({
    required String name,
    required String zone,
    required int hr,
    required int spo2,
    required double temp,
    required int sys,
    required int dia,
  }) {
    final score = calculateRiskScore(
      hr: hr,
      spo2: spo2,
      temp: temp,
      systolic: sys,
    );

    return WorkerVitals(
      workerName: name,
      heartRate: hr,
      spo2: spo2,
      temperature: temp,
      systolic: sys,
      diastolic: dia,
      riskScore: score,
      status: riskStatus(score),
      hrHistory: [hr - 10, hr - 7, hr - 5, hr - 2, hr.toDouble()]
          .map((e) => e.toDouble())
          .toList(),
      tempHistory: [temp - 0.4, temp - 0.3, temp - 0.2, temp - 0.1, temp],
      spo2History: [spo2 + 1, spo2 + 1, spo2, spo2, spo2]
          .map((e) => e.toDouble())
          .toList(),
      zone: zone,
      online: true,
    );
  }

  @override
  void initState() {
    super.initState();
    initAiModel();
    startSimulation();
  }

  @override
  void dispose() {
    timer?.cancel();
    aiService.dispose();
    super.dispose();
  }

  Future<void> initAiModel() async {
    try {
      await aiService.init();
      if (!mounted) return;
      setState(() {
        aiModelStatus = 'AI model loaded successfully';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiModelStatus = 'Error loading AI model: $e';
      });
    }
  }

  void startSimulation() {
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        workers = workers.map(simulateWorker).toList();
      });
    });
  }

  WorkerVitals simulateWorker(WorkerVitals worker) {
    final newHeartRate =
        clampInt(worker.heartRate + random.nextInt(11) - 5, 70, 150);
    final newSpo2 = clampInt(worker.spo2 + random.nextInt(3) - 1, 88, 100);
    final newTemp = clampDouble(
      worker.temperature + ((random.nextDouble() * 0.4) - 0.2),
      36.4,
      39.8,
    );
    final newSys = clampInt(worker.systolic + random.nextInt(9) - 4, 88, 160);
    final newDia = clampInt(worker.diastolic + random.nextInt(9) - 4, 58, 100);

    final newRisk = calculateRiskScore(
      hr: newHeartRate,
      spo2: newSpo2,
      temp: newTemp,
      systolic: newSys,
    );

    return worker.copyWith(
      heartRate: newHeartRate,
      spo2: newSpo2,
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      systolic: newSys,
      diastolic: newDia,
      riskScore: newRisk,
      status: riskStatus(newRisk),
      hrHistory: updateHistory(worker.hrHistory, newHeartRate.toDouble()),
      tempHistory: updateHistory(worker.tempHistory, newTemp),
      spo2History: updateHistory(worker.spo2History, newSpo2.toDouble()),
    );
  }

  List<double> updateHistory(List<double> history, double newValue) {
    final updated = List<double>.from(history)..add(newValue);
    if (updated.length > 10) {
      updated.removeAt(0);
    }
    return updated;
  }

  int clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  double clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  double calculateRiskScore({
    required int hr,
    required int spo2,
    required double temp,
    required int systolic,
  }) {
    double score = 0;

    if (hr >= 90) score += 10;
    if (hr >= 110) score += 15;
    if (hr >= 130) score += 20;

    if (temp >= 37.5) score += 10;
    if (temp >= 38.0) score += 15;
    if (temp >= 39.0) score += 20;

    if (spo2 <= 95) score += 10;
    if (spo2 <= 92) score += 20;
    if (spo2 <= 90) score += 25;

    if (systolic <= 100) score += 10;
    if (systolic <= 90) score += 15;

    if (score > 100) score = 100;
    return score;
  }

  String riskStatus(double score) {
    if (score <= 25) return 'Normal';
    if (score <= 50) return 'Warning';
    if (score <= 75) return 'High Risk';
    return 'Critical';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      case 'High Risk':
        return Colors.deepOrange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<double> buildFeatureVectorFromWorker(WorkerVitals worker) {
    // This is a simple bridge for testing the ONNX model.
    // It does NOT reproduce the real WESAD feature extraction pipeline.
    // It only builds a numeric vector with the same size as the trained model input.

    final hrMean = worker.hrHistory.isEmpty
        ? worker.heartRate.toDouble()
        : worker.hrHistory.reduce((a, b) => a + b) / worker.hrHistory.length;

    final tempMean = worker.tempHistory.isEmpty
        ? worker.temperature
        : worker.tempHistory.reduce((a, b) => a + b) / worker.tempHistory.length;

    final spo2Mean = worker.spo2History.isEmpty
        ? worker.spo2.toDouble()
        : worker.spo2History.reduce((a, b) => a + b) / worker.spo2History.length;

    final hrStd = computeStd(worker.hrHistory);
    final tempStd = computeStd(worker.tempHistory);
    final spo2Std = computeStd(worker.spo2History);

    final baseFeatures = <double>[
      worker.heartRate / 200.0,
      worker.spo2 / 100.0,
      worker.temperature / 40.0,
      worker.systolic / 200.0,
      worker.diastolic / 120.0,
      worker.riskScore / 100.0,
      hrMean / 200.0,
      tempMean / 40.0,
      spo2Mean / 100.0,
      hrStd / 50.0,
      tempStd / 5.0,
      spo2Std / 10.0,
    ];

    final features = <double>[];
    while (features.length < modelFeatureCount) {
      for (final f in baseFeatures) {
        if (features.length < modelFeatureCount) {
          features.add(f);
        } else {
          break;
        }
      }
    }

    return features;
  }

  double computeStd(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  Future<void> runAiPrediction() async {
    if (!aiService.isInitialized) {
      setState(() {
        aiModelStatus = 'AI model is not initialized';
      });
      return;
    }

    setState(() {
      isAiLoading = true;
    });

    try {
      final selectedWorker = workers[selectedWorkerIndex];
      final features = buildFeatureVectorFromWorker(selectedWorker);

      final result = await aiService.predict(features);

      if (!mounted) return;
      setState(() {
        aiPredictionLabel = result.riskLabel;
        aiStressProbability = result.probStress;
        aiBaselineProbability = result.probBaseline;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiPredictionLabel = 'Prediction error';
        aiModelStatus = 'Prediction failed: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isAiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedWorker = workers[selectedWorkerIndex];

    final pages = [
      SupervisorDashboardScreen(
        workers: workers,
        selectedWorkerIndex: selectedWorkerIndex,
        onSelectWorker: (index) {
          setState(() {
            selectedWorkerIndex = index;
          });
        },
        getStatusColor: getStatusColor,
      ),
      WorkerDetailsScreen(
        worker: selectedWorker,
        getStatusColor: getStatusColor,
        aiModelStatus: aiModelStatus,
        aiPredictionLabel: aiPredictionLabel,
        aiStressProbability: aiStressProbability,
        aiBaselineProbability: aiBaselineProbability,
        isAiLoading: isAiLoading,
        onRunPrediction: runAiPrediction,
      ),
      AlertsScreen(
        workers: workers,
        getStatusColor: getStatusColor,
      ),
      TrendsScreen(
        worker: selectedWorker,
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Supervisor',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Worker',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Trends',
          ),
        ],
      ),
    );
  }
}

class SupervisorDashboardScreen extends StatelessWidget {
  final List<WorkerVitals> workers;
  final int selectedWorkerIndex;
  final ValueChanged<int> onSelectWorker;
  final Color Function(String) getStatusColor;

  const SupervisorDashboardScreen({
    super.key,
    required this.workers,
    required this.selectedWorkerIndex,
    required this.onSelectWorker,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final criticalCount = workers.where((w) => w.status == 'Critical').length;
    final highRiskCount = workers.where((w) => w.status == 'High Risk').length;
    final warningCount = workers.where((w) => w.status == 'Warning').length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supervisor Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Monitor all workers in real time',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Critical',
                    value: '$criticalCount',
                    color: Colors.red,
                    icon: Icons.priority_high,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: 'High Risk',
                    value: '$highRiskCount',
                    color: Colors.deepOrange,
                    icon: Icons.warning_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: 'Warning',
                    value: '$warningCount',
                    color: Colors.orange,
                    icon: Icons.info_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Workers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  final isSelected = selectedWorkerIndex == index;

                  return GestureDetector(
                    onTap: () => onSelectWorker(index),
                    child: WorkerListCard(
                      worker: worker,
                      statusColor: getStatusColor(worker.status),
                      isSelected: isSelected,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkerDetailsScreen extends StatelessWidget {
  final WorkerVitals worker;
  final Color Function(String) getStatusColor;
  final String aiModelStatus;
  final String aiPredictionLabel;
  final double aiStressProbability;
  final double aiBaselineProbability;
  final bool isAiLoading;
  final VoidCallback onRunPrediction;

  const WorkerDetailsScreen({
    super.key,
    required this.worker,
    required this.getStatusColor,
    required this.aiModelStatus,
    required this.aiPredictionLabel,
    required this.aiStressProbability,
    required this.aiBaselineProbability,
    required this.isAiLoading,
    required this.onRunPrediction,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(worker.status);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF9B45)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.workerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    worker.zone,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          worker.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${worker.riskScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                MetricCard(
                  title: 'Heart Rate',
                  value: '${worker.heartRate} bpm',
                  icon: Icons.favorite,
                  color: Colors.red,
                ),
                MetricCard(
                  title: 'SpO₂',
                  value: '${worker.spo2}%',
                  icon: Icons.bloodtype,
                  color: Colors.blue,
                ),
                MetricCard(
                  title: 'Temperature',
                  value: '${worker.temperature.toStringAsFixed(1)} °C',
                  icon: Icons.thermostat,
                  color: Colors.deepOrange,
                ),
                MetricCard(
                  title: 'Blood Pressure',
                  value: worker.bloodPressure,
                  icon: Icons.monitor_heart,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TrendCard(
              title: 'Heart Rate Trend',
              valueLabel: '${worker.heartRate} bpm',
              lineColor: Colors.red,
              points: worker.hrHistory,
              minY: 60,
              maxY: 150,
            ),
            const SizedBox(height: 12),
            TrendCard(
              title: 'Temperature Trend',
              valueLabel: '${worker.temperature.toStringAsFixed(1)} °C',
              lineColor: Colors.deepOrange,
              points: worker.tempHistory,
              minY: 36,
              maxY: 40,
            ),
            const SizedBox(height: 12),
            TrendCard(
              title: 'SpO₂ Trend',
              valueLabel: '${worker.spo2}%',
              lineColor: Colors.blue,
              points: worker.spo2History,
              minY: 88,
              maxY: 100,
            ),
            const SizedBox(height: 20),
            InfoCard(
              title: 'AI Interpretation',
              description: buildInterpretation(worker),
              icon: Icons.psychology_alt,
              iconColor: statusColor,
            ),
            const SizedBox(height: 16),
            AiResultCard(
              aiModelStatus: aiModelStatus,
              aiPredictionLabel: aiPredictionLabel,
              aiStressProbability: aiStressProbability,
              aiBaselineProbability: aiBaselineProbability,
              isAiLoading: isAiLoading,
              onRunPrediction: onRunPrediction,
            ),
          ],
        ),
      ),
    );
  }

  String buildInterpretation(WorkerVitals worker) {
    if (worker.status == 'Critical') {
      return 'Critical multimodal risk detected. Immediate medical or supervisor intervention is recommended.';
    }
    if (worker.status == 'High Risk') {
      return 'Worker shows strong signs of physiological stress. Rest, hydration, and close monitoring are recommended.';
    }
    if (worker.status == 'Warning') {
      return 'Some parameters are drifting from normal conditions. Preventive action may be required.';
    }
    return 'Worker is currently stable with no major warning signs.';
  }
}

class AiResultCard extends StatelessWidget {
  final String aiModelStatus;
  final String aiPredictionLabel;
  final double aiStressProbability;
  final double aiBaselineProbability;
  final bool isAiLoading;
  final VoidCallback onRunPrediction;

  const AiResultCard({
    super.key,
    required this.aiModelStatus,
    required this.aiPredictionLabel,
    required this.aiStressProbability,
    required this.aiBaselineProbability,
    required this.isAiLoading,
    required this.onRunPrediction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local AI Model',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            aiModelStatus,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prediction: $aiPredictionLabel',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text('Stress probability: ${aiStressProbability.toStringAsFixed(3)}'),
          const SizedBox(height: 4),
          Text('Baseline probability: ${aiBaselineProbability.toStringAsFixed(3)}'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAiLoading ? null : onRunPrediction,
              icon: isAiLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.memory),
              label: Text(isAiLoading ? 'Running...' : 'Run AI Prediction'),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertsScreen extends StatelessWidget {
  final List<WorkerVitals> workers;
  final Color Function(String) getStatusColor;

  const AlertsScreen({
    super.key,
    required this.workers,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final alerts = buildAllAlerts(workers);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alerts Center',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: alerts.isEmpty
                  ? const Center(child: Text('No active alerts'))
                  : ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return AlertTile(
                          title: alert.title,
                          subtitle: alert.subtitle,
                          color: alert.color,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppAlert> buildAllAlerts(List<WorkerVitals> workers) {
    final all = <AppAlert>[];

    for (final worker in workers) {
      if (worker.temperature >= 38.0) {
        all.add(AppAlert(
          title: 'Heat Stress Warning - ${worker.workerName}',
          subtitle: 'Temperature is high in ${worker.zone}.',
          color: Colors.deepOrange,
        ));
      }
      if (worker.heartRate >= 110) {
        all.add(AppAlert(
          title: 'Elevated Heart Rate - ${worker.workerName}',
          subtitle: 'Heart rate is above safe comfort level.',
          color: Colors.red,
        ));
      }
      if (worker.spo2 <= 95) {
        all.add(AppAlert(
          title: 'Low SpO₂ - ${worker.workerName}',
          subtitle: 'Possible oxygen deficiency or respiratory strain.',
          color: Colors.blue,
        ));
      }
      if (worker.systolic <= 100) {
        all.add(AppAlert(
          title: 'Low Blood Pressure - ${worker.workerName}',
          subtitle: 'Possible dehydration, fatigue, or collapse risk.',
          color: Colors.purple,
        ));
      }
      if (worker.riskScore >= 50) {
        all.add(AppAlert(
          title: 'Supervisor Attention Needed - ${worker.workerName}',
          subtitle: 'Overall risk score is elevated.',
          color: Colors.orange,
        ));
      }
    }

    return all;
  }
}

class TrendsScreen extends StatelessWidget {
  final WorkerVitals worker;

  const TrendsScreen({
    super.key,
    required this.worker,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trends - ${worker.workerName}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            TrendCard(
              title: 'Heart Rate',
              valueLabel: '${worker.heartRate} bpm',
              lineColor: Colors.red,
              points: worker.hrHistory,
              minY: 60,
              maxY: 150,
            ),
            const SizedBox(height: 12),
            TrendCard(
              title: 'Temperature',
              valueLabel: '${worker.temperature.toStringAsFixed(1)} °C',
              lineColor: Colors.deepOrange,
              points: worker.tempHistory,
              minY: 36,
              maxY: 40,
            ),
            const SizedBox(height: 12),
            TrendCard(
              title: 'SpO₂',
              valueLabel: '${worker.spo2}%',
              lineColor: Colors.blue,
              points: worker.spo2History,
              minY: 88,
              maxY: 100,
            ),
          ],
        ),
      ),
    );
  }
}

class AppAlert {
  final String title;
  final String subtitle;
  final Color color;

  AppAlert({
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkerListCard extends StatelessWidget {
  final WorkerVitals worker;
  final Color statusColor;
  final bool isSelected;

  const WorkerListCard({
    super.key,
    required this.worker,
    required this.statusColor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF4EA) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFB36C) : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(Icons.person, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.workerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker.zone,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  worker.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child:
                    SmallValue(label: 'HR', value: '${worker.heartRate} bpm'),
              ),
              Expanded(
                child: SmallValue(label: 'SpO₂', value: '${worker.spo2}%'),
              ),
              Expanded(
                child: SmallValue(
                  label: 'Temp',
                  value: '${worker.temperature.toStringAsFixed(1)} °C',
                ),
              ),
              Expanded(
                child: SmallValue(
                  label: 'Risk',
                  value: '${worker.riskScore.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SmallValue extends StatelessWidget {
  final String label;
  final String value;

  const SmallValue({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class TrendCard extends StatelessWidget {
  final String title;
  final String valueLabel;
  final Color lineColor;
  final List<double> points;
  final double minY;
  final double maxY;

  const TrendCard({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.lineColor,
    required this.points,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                valueLabel,
                style: TextStyle(
                  color: lineColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: MiniLineChartPainter(
                points: points,
                lineColor: lineColor,
                minY: minY,
                maxY: maxY,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniLineChartPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final double minY;
  final double maxY;

  MiniLineChartPainter({
    required this.points,
    required this.lineColor,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.18)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.length < 2) return;

    final path = Path();
    final fillPath = Path();

    double dx(int index) => index * (size.width / (points.length - 1));

    double dy(double value) {
      final normalized = ((value - minY) / (maxY - minY)).clamp(0.0, 1.0);
      return size.height - (normalized * size.height);
    }

    path.moveTo(dx(0), dy(points[0]));
    fillPath.moveTo(dx(0), size.height);
    fillPath.lineTo(dx(0), dy(points[0]));

    for (int i = 1; i < points.length; i++) {
      path.lineTo(dx(i), dy(points[i]));
      fillPath.lineTo(dx(i), dy(points[i]));
    }

    fillPath.lineTo(dx(points.length - 1), size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.25),
          lineColor.withOpacity(0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(dx(i), dy(points[i])), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.12),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlertTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const AlertTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(Icons.warning_amber_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}