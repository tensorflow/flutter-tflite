# BertQA

An end-to-end example of BERT Question & Answer application using Tensorflow
Lite in Flutter. It includes support for both Android and IOS.

## Download model and labels

To build the project, you must first download the Mobilebert TensorFlow Lite
model, its corresponding labels and list sample question. You can do this by running sh
./scripts/download_model.sh from the root folder of the repository.

## About the sample

- You can use Flutter-supported IDEs such as Android Studio or Visual Studio.
  This project has been tested on Android Studio Flamingo.
- Before building, ensure that you have downloaded the model and the labels by
  following a set of instructions.

### Screenshot
#### Android
![Android QA](screenshots/android_question.png)
![Android Detail](screenshots/android_qa_detail.png)

#### IOS
![IOS](screenshots/ios_question.png)
![IOS](screenshots/ios_qa_detail.png)