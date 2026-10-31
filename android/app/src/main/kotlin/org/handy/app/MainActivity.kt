package org.handy.app

import org.handy.app.plugins.AppPlugin
import org.handy.app.plugins.BatteryPlugin
import org.handy.app.plugins.ServicePlugin
import org.handy.app.plugins.TilePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AppPlugin())
        flutterEngine.plugins.add(BatteryPlugin())
        flutterEngine.plugins.add(ServicePlugin())
        flutterEngine.plugins.add(TilePlugin())
        ServiceState.attachFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        flutterEngine?.let(ServiceState::detachFlutterEngine)
        super.onDestroy()
    }
}
