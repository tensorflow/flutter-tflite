# Download model
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/audio_classification/flutter/lite-model_yamnet_classification_tflite_1.tflite \
    -o assets/models/yamnet.tflite

# Unzip model to get labels and vocab
unzip -o assets/models/yamnet.tflite \
    -d assets/models/