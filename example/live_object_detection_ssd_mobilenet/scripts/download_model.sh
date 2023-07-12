# Download model
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/object_detection/android/lite-model_ssd_mobilenet_v1_1_metadata_2.tflite \
    -o assets/models/ssd_mobilenet.tflite

# Unzip model to get labels and vocab
unzip -o assets/models/ssd_mobilenet.tflite \
    -d assets/models/
