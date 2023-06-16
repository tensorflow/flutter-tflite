# Delete old models
rm -r assets/models/

# Create folder if not already exists
mkdir assets/models

# Download models
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite \
    -o assets/models/magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite

curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite \
    -o assets/models/magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite