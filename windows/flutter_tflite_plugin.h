#ifndef FLUTTER_PLUGIN_FLUTTER_TFLITE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_TFLITE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_tflite {

class FlutterTflitePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterTflitePlugin();

  virtual ~FlutterTflitePlugin();

  // Disallow copy and assign.
  FlutterTflitePlugin(const FlutterTflitePlugin&) = delete;
  FlutterTflitePlugin& operator=(const FlutterTflitePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_tflite

#endif  // FLUTTER_PLUGIN_FLUTTER_TFLITE_PLUGIN_H_
