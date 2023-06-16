# Delete old models
rm -r assets/models/

# Create folder if not already exists
mkdir assets/models

# Download model
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/image_classification/android/mobilenet_v1_1.0_224_quantized_1_metadata_1.tflite \
    -o assets/models/mobilenet_quant.tflite

# Unzip model to get labels and vocab
unzip assets/models/mobilenet_quant.tflite \
    -d assets/models/
