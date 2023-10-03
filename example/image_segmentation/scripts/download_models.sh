# Download model
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/image_segmentation/flutter/lite-model_deeplabv3_1_metadata_2.tflite \
    -o assets/deeplabv3.tflite

# Unzip model to get labels
unzip -o assets/deeplabv3.tflite \
    -d assets/
