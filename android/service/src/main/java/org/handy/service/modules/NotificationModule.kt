package org.handy.service.modules

import android.app.Notification.FOREGROUND_SERVICE_IMMEDIATE
import android.app.Service
import android.app.Service.STOP_FOREGROUND_REMOVE
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import org.handy.common.Components
import org.handy.common.GlobalState
import org.handy.common.QuickAction
import org.handy.common.ensureNotificationChannel
import org.handy.common.quickIntent
import org.handy.common.receiveBroadcastFlow
import org.handy.common.startForeground
import org.handy.common.toPendingIntent
import org.handy.core.Core
import org.handy.service.R
import org.handy.service.ServiceConfig
import org.handy.service.models.NotificationParams
import org.handy.service.models.getSpeedTrafficText
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch

private data class ExtendedNotificationParams(
    val title: String,
    val stopText: String,
    val showStopAction: Boolean,
    val contentText: String,
)

private val NotificationParams.extended: ExtendedNotificationParams
    get() = ExtendedNotificationParams(
        title,
        stopText,
        showStopAction,
        Core.getSpeedTrafficText(onlyStatisticsProxy),
    )

internal class NotificationModule(
    private val service: Service,
    private val scope: CoroutineScope,
) : ServiceModule {
    override fun start() {
        service.ensureNotificationChannel()
        update(ServiceConfig.notificationParams.value.extended)
        scope.launch {
            // Some ROMs, vivo's among them, drop updates posted behind the
            // keyguard, so unlocking restarts the loop to post once more.
            // SystemUI, an app, sends USER_PRESENT, which a receiver that is
            // not exported never gets; all three actions are protected.
            service.receiveBroadcastFlow(exported = true) {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            }.map { intent ->
                intent.action != Intent.ACTION_SCREEN_OFF
            }.onStart {
                emit(isScreenOn())
            }.collectLatest { screenOn ->
                if (!screenOn) return@collectLatest
                combine(
                    flow {
                        while (true) {
                            delay(1_000)
                            emit(Unit)
                        }
                    },
                    ServiceConfig.notificationParams,
                ) { _, params ->
                    params.extended
                }.distinctUntilChanged()
                    .collect(::update)
            }
        }
    }

    private fun isScreenOn() =
        service.getSystemService<PowerManager>()?.isInteractive ?: true

    private val notificationBuilder: NotificationCompat.Builder by lazy {
        val intent = Intent().setComponent(Components.mainActivity)

        NotificationCompat.Builder(
            service,
            GlobalState.NOTIFICATION_CHANNEL,
        ).apply {
            setSmallIcon(R.drawable.ic)
            setContentTitle("Handy")
            setContentIntent(intent.toPendingIntent)
            setPriority(NotificationCompat.PRIORITY_LOW)
            setCategory(NotificationCompat.CATEGORY_SERVICE)
            setOngoing(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                foregroundServiceBehavior = FOREGROUND_SERVICE_IMMEDIATE
            }
            setShowWhen(true)
            setOnlyAlertOnce(true)
        }
    }

    private val stopIntent by lazy { QuickAction.STOP.quickIntent.toPendingIntent }

    private fun update(params: ExtendedNotificationParams) {
        service.startForeground(
            with(notificationBuilder) {
                setContentTitle(params.title)
                setContentText(params.contentText)
                clearActions()
                if (params.showStopAction) {
                    addAction(0, params.stopText, stopIntent)
                }
                build()
            },
        )
    }

    @Suppress("DEPRECATION")
    override fun stop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            service.stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            service.stopForeground(true)
        }
    }
}
