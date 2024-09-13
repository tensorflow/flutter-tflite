# Object Detection

|      | Android | iOS | Linux | Mac | Windows | Web |
|------|---------|-----|-------|-----|---------|-----|
| live | ✅       | ✅   |   [🚧](https://github.com/flutter/flutter/issues/41710)   |  [🚧](https://github.com/flutter/flutter/issues/41708)  |         |     |

Live object detection example following [this](https://www.tensorflow.org/lite/examples/object_detection/overview) example.

## Overview

This application is a simple demonstration of the [tflite_flutter](https://pub.dev/packages/tflite_flutter) package.

Object detection applies on an image stream from camera (portrait mode only for the showcase purpose).
All expensive and heavy operations are performed in a separate background isolate.

## How to start

Run 'sh ./scripts/download_model.sh' from your repo core folder to download tf models.

## Sample output

|![Pixel](output_Pixel7.gif)|![iPhone](output_iPhone.gif)|![iPad](output_iPad.gif)|
