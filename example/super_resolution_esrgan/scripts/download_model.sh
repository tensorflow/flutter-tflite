# Delete old models
rm -r assets/models/

# Create folder if not already exists
mkdir assets/models

# Download model
curl https://tfhub.dev/captain-pool/lite-model/esrgan-tf2/1?lite-format=tflite \
    -o assets/models/esrgan-tf2.tflite \
    -L
