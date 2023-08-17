/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.tensorflow.audio_classification.audio_classification

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioRecord
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL =
            "org.tensorflow.audio_classification/audio_record"
        private const val REQUEST_CODE = 100
        private const val ERROR_CODE = "android_error"
    }

    private var audioRecord: AudioRecord? = null
    private var permissionResult: MethodChannel.Result? = null
    private var sampleRate: Int = 0
    private var requiredInputBufferSize: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissionAndCreateRecorder" -> {
                    sampleRate = call.argument<Int>("sampleRate")!!
                    requiredInputBufferSize =
                        call.argument<Int>("requiredInputBuffer")!!
                    requestPermissionAndCreateRecorder(
                        sampleRate,
                        requiredInputBufferSize,
                        result
                    )
                }

                "startRecord" -> {
                    startRecord()
                }

                "getAudioFloatArray" -> {
                    result.success(getAudioFloatArray())
                }

                "closeRecorder" -> {
                    result.success(closeRecorder())
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                createAudioRecord(sampleRate, requiredInputBufferSize)
                permissionResult?.success(true)
                permissionResult = null
            } else {
                permissionResult?.error(
                    ERROR_CODE,
                    "Please grant this app recording permission so it can classify sounds.",
                    ""
                )
                permissionResult = null
            }
        }
    }

    private fun requestPermission() {
        val currentMicrophonePermission = ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        )

        if (currentMicrophonePermission != PackageManager.PERMISSION_GRANTED)
            ActivityCompat.requestPermissions(
                context as Activity, arrayOf(
                    Manifest.permission.RECORD_AUDIO
                ), REQUEST_CODE
            )
    }

    // Requests permission to record audio and creates a recorder.
    @SuppressLint("MissingPermission")
    private fun requestPermissionAndCreateRecorder(
        sampleRate: Int,
        requiredInputBufferSize: Int,
        result: MethodChannel.Result
    ) {
        // Store the Flutter result callback.
        permissionResult = result
        when (PackageManager.PERMISSION_GRANTED) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.RECORD_AUDIO
            ) -> {
                // If permission is granted, initialize the recorder.
                createAudioRecord(sampleRate, requiredInputBufferSize)
                permissionResult?.success(true)
                permissionResult = null
            }

            else -> {
                requestPermission()
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun createAudioRecord(
        sampleRate: Int,
        requiredInputBufferSize: Int
    ) {
        val bufferSizeMultiplier = 2
        val modelRequiredBufferSize: Int =
            requiredInputBufferSize * Float.SIZE_BYTES * bufferSizeMultiplier

        audioRecord = AudioRecord(6, sampleRate, 1, 4, modelRequiredBufferSize)
    }

    // Starts the recorder. This function should be called after the recorder has been created.
    private fun startRecord() {
        audioRecord?.startRecording()
    }

    private fun getAudioFloatArray(): FloatArray {
        audioRecord?.let {
            val newValue = FloatArray(it.bufferSizeInFrames * 1)
            it.read(
                newValue,
                0,
                newValue.size,
                AudioRecord.READ_NON_BLOCKING
            )
            return newValue
        } ?: kotlin.run {
            return floatArrayOf()
        }
    }

    private fun closeRecorder(): Boolean {
        return try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
            true
        }catch (e: Exception){
            false
        }
    }
}
