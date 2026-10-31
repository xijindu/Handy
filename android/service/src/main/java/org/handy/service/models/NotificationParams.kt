package org.handy.service.models

data class NotificationParams(
    val title: String = "Handy",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
    val showStopAction: Boolean = true,
)
