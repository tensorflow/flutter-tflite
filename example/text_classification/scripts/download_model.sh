# Download model
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/text_classification/text_classification.tflite \
    -o assets/models/text_classification.tflite

# Unzip model to get labels and vocab
unzip -o assets/models/text_classification.tflite \
    -d assets/models/ \
    -x labels.txt