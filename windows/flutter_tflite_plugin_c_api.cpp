#include "include/flutter_tflite/flutter_tflite_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_tflite_plugin.h"

void FlutterTflitePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_tflite::FlutterTflitePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
