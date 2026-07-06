package io.szymanski.invee

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val SCANNER_CHANNEL = "io.szymanski.invee/scanner"

        // Newer ReaderService API (no barcodebase.jar required)
        private const val ACTION_PASS_DATA = "com.cipherlab.barcodebaseapi.PASS_DATA_2_APP"
        // Older fallback used on some firmware versions
        private const val ACTION_PASS_TO_APP = "com.cipherlab.barcode.GeneralString.Intent_PASS_TO_APP"

        private const val EXTRA_DATA = "Decoder_Data"
        private const val EXTRA_CODE_TYPE = "Decoder_CodeType_String"
    }

    private var eventSink: EventChannel.EventSink? = null

    private val scanReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val data = intent.getStringExtra(EXTRA_DATA) ?: return
            val codeType = intent.getStringExtra(EXTRA_CODE_TYPE) ?: ""
            eventSink?.success(mapOf("data" to data, "codeType" to codeType))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    eventSink = sink
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter().apply {
            addAction(ACTION_PASS_DATA)
            addAction(ACTION_PASS_TO_APP)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(scanReceiver, filter, RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(scanReceiver, filter)
        }
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(scanReceiver)
    }
}
