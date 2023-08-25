# Download model
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/bert_qa/flutter/bert_qa_lite-model_mobilebert_1_metadata_1.tflite \
    -o assets/mobilebert.tflite

unzip -o assets/mobilebert.tflite \
    -d assets/

# Download QA
curl https://storage.googleapis.com/download.tensorflow.org/models/tflite/bert_qa/contents_from_squad.json \
    -o assets/qa.json
