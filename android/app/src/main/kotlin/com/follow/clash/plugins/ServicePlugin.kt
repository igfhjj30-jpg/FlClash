package com.follow.clash.plugins

import android.content.Context
import android.content.Intent
import android.provider.Settings
import com.follow.clash.ServiceController
import com.follow.clash.ServiceState
import com.follow.clash.common.Components
import com.follow.clash.models.SharedState
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class ServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var scope: CoroutineScope
    private val gson = Gson()
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        channel = MethodChannel(binding.binaryMessenger, "${Components.PACKAGE_NAME}/service")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
        ServiceController.setEventListener(null)
    }

    override fun onMethodCall(call: MethodCall, rawResult: MethodChannel.Result) {
        // Most handlers below reply from a scope worker on Dispatchers.Default,
        // but a MethodChannel.Result has to be answered on the platform thread.
        // Wrapping once here covers every branch, including notImplemented.
        val result = MainThreadResult(rawResult)
        when (call.method) {
            "init" -> initialize(result)
            "shutdown" -> shutdown(result)
            "invokeMethod" -> invokeMethod(call, result)
            "getRunTime" -> getRunTime(result)
            "syncState" -> syncState(call, result)
            "start" -> start(result)
            "stop" -> stop(result)
            "packetTunnelStatus" -> scope.launch {
                runCatching { ServiceController.getPacketTunnelStatus() }
                    .onSuccess { result.success(it) }
                    .onFailure { result.error("TUNNEL_STATUS", "Unable to read VPN status", null) }
            }
            "openVpnSettings" -> {
                runCatching {
                    context.startActivity(Intent(Settings.ACTION_VPN_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }.onSuccess { result.success(true) }
                    .onFailure { result.error("VPN_SETTINGS", "Unable to open VPN settings", null) }
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: MethodChannel.Result) {
        ServiceController.setEventListener(::sendEvent)
            .onSuccess { result.success("") }
            .onFailure { error -> result.success(error.message.orEmpty()) }
    }

    private fun shutdown(result: MethodChannel.Result) {
        scope.launch {
            ServiceController.unbind()
            result.success(true)
        }
    }

    private fun invokeMethod(call: MethodCall, result: MethodChannel.Result) {
        val data = call.arguments as? String
        if (data == null) {
            result.error("INVALID_ARGUMENT", "Method call payload must be a string", null)
            return
        }
        // Inline rather than a coroutine per call, which could swap two: watchRoute
        // keeps the latest intent by the order calls reach the Core
        // (dispatchMethodCall in core/method.go), and this only hands data over.
        ServiceController.invokeMethod(data) { response ->
            result.success(response)
        }.onFailure { error ->
            result.error("CORE_ERROR", error.message, null)
        }
    }

    private fun getRunTime(result: MethodChannel.Result) {
        scope.launch {
            result.success(ServiceState.refresh())
        }
    }

    private fun syncState(call: MethodCall, result: MethodChannel.Result) {
        val data = call.arguments as? String
        val state = runCatching {
            gson.fromJson(data, SharedState::class.java)
        }.getOrNull()
        if (state == null) {
            result.success("Invalid shared state")
            return
        }
        scope.launch {
            ServiceState.syncSharedState(state)
            result.success("")
        }
    }

    private fun start(result: MethodChannel.Result) {
        ServiceState.requestStart()
        result.success(true)
    }

    private fun stop(result: MethodChannel.Result) {
        ServiceState.requestStop()
        result.success(true)
    }

    private fun sendEvent(value: String?) {
        scope.launch(Dispatchers.Main) {
            channel.invokeMethod("event", value)
        }
    }
}
