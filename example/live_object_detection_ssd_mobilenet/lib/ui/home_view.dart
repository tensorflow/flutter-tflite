import 'package:flutter/material.dart';
import 'package:live_object_detection_ssd_mobilenet/tflite/recognition.dart';
import 'package:live_object_detection_ssd_mobilenet/tflite/stats.dart';
import 'package:live_object_detection_ssd_mobilenet/ui/box_widget.dart';
import 'package:live_object_detection_ssd_mobilenet/ui/camera_view_singleton.dart';

import 'camera_view.dart';

/// [HomeView] stacks [CameraView] and [BoxWidget]s with bottom sheet for stats
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Results to draw bounding boxes
  List<Recognition>? results;

  /// Realtime stats
  Stats? stats;

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) => Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            'Live Object Detection',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          children: <Widget>[
            // Camera View
            CameraView(resultsCallback, statsCallback),
            // Bounding boxes
            boundingBoxes(results),
            // Bottom Sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.1,
                maxChildSize: 0.5,
                builder: (_, ScrollController scrollController) => Container(
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BORDER_RADIUS_BOTTOM_SHEET),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.keyboard_arrow_up,
                              size: 48, color: Colors.orange),
                          (stats != null)
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      StatsRow('Conversion time:',
                                          '${stats!.conversionTime} ms'),
                                      StatsRow('Pre-processing time:',
                                          '${stats!.preProcessingTime} ms'),
                                      StatsRow('Inference time:',
                                          '${stats!.inferenceTime} ms'),
                                      StatsRow('Total prediction time:',
                                          '${stats!.totalElapsedTime} ms'),
                                      StatsRow('Frame',
                                          '${CameraViewSingleton.inputImageSize.width} X ${CameraViewSingleton.inputImageSize.height}'),
                                    ],
                                  ),
                                )
                              : Container()
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      );

  /// Returns Stack of bounding boxes
  Widget boundingBoxes(List<Recognition>? results) {
    if (results == null) {
      return const Spacer();
    }
    return Stack(
      children: results.map((box) => BoxWidget(result: box)).toList(),
    );
  }

  /// Callback to get inference results from [CameraView]
  void resultsCallback(List<Recognition> results) {
    setState(() {
      this.results = results;
    });
  }

  /// Callback to get inference stats from [CameraView]
  void statsCallback(Stats stats) {
    setState(() {
      this.stats = stats;
    });
  }

  static const BOTTOM_SHEET_RADIUS = Radius.circular(24.0);
  static const BORDER_RADIUS_BOTTOM_SHEET = BorderRadius.only(
      topLeft: BOTTOM_SHEET_RADIUS, topRight: BOTTOM_SHEET_RADIUS);
}

/// Row for one Stats field
class StatsRow extends StatelessWidget {
  final String left;
  final String right;

  const StatsRow(this.left, this.right, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left), Text(right)],
      ),
    );
  }
}
