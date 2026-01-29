package com.sleekscan.documentscanner

import android.content.Context
import android.view.LayoutInflater
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.widget.TextView
import android.widget.ImageView

class ListTileNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.native_ad_list_tile, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val iconView = adView.findViewById<ImageView>(R.id.ad_icon)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        nativeAd.icon?.drawable?.let {
            iconView.setImageDrawable(it)
            adView.iconView = iconView
        } ?: run {
            adView.iconView = null
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
} 