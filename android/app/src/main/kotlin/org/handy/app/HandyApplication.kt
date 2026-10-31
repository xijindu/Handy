package org.handy.app

import android.app.Application
import android.content.Context
import org.handy.common.GlobalState

class HandyApplication : Application() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}
