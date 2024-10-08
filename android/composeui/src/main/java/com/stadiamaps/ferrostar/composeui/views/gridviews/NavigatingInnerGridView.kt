package com.stadiamaps.ferrostar.composeui.views.gridviews

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Navigation
import androidx.compose.material.icons.filled.VolumeOff
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stadiamaps.ferrostar.composeui.R
import com.stadiamaps.ferrostar.composeui.views.controls.NavigationUIButton
import com.stadiamaps.ferrostar.composeui.views.controls.NavigationUIZoomButton

@Composable
fun NavigatingInnerGridView(
    modifier: Modifier,
    showMute: Boolean = true,
    isMuted: Boolean?,
    onClickMute: () -> Unit = {},
    showZoom: Boolean = true,
    onClickZoomIn: () -> Unit = {},
    onClickZoomOut: () -> Unit = {},
    showCentering: Boolean = true,
    onClickCenter: () -> Unit = {},
    topCenter: @Composable () -> Unit = { Spacer(Modifier.width(12.dp)) },
    centerStart: @Composable () -> Unit = { Spacer(Modifier.width(12.dp)) },
    bottomEnd: @Composable () -> Unit = { Spacer(Modifier.width(12.dp)) }
) {
  InnerGridView(
      modifier,
      topStart = {
        // TODO: SpeedLimitView goes here
      },
      topCenter = topCenter,
      topEnd = {
        if (showMute && isMuted != null) {
          NavigationUIButton(onClick = onClickMute) {
            if (isMuted) {
              Icon(
                  Icons.AutoMirrored.Filled.VolumeOff,
                  contentDescription = stringResource(id = R.string.unmute_description))
            } else {
              Icon(
                  Icons.AutoMirrored.Filled.VolumeUp,
                  contentDescription = stringResource(id = R.string.mute_description))
            }
          }
        }
      },
      centerStart = centerStart,
      centerEnd = {
        if (showZoom) {
          NavigationUIZoomButton(onClickZoomIn, onClickZoomOut)
        }
      },
      bottomStart = {
        if (showCentering) {
          NavigationUIButton(onClick = onClickCenter) {
            Icon(
                Icons.Filled.Navigation,
                contentDescription = stringResource(id = R.string.recenter))
          }
        }
      },
      bottomEnd = bottomEnd)
}

@Preview(device = Devices.PIXEL_5)
@Composable
fun NavigatingInnerGridViewPreview() {
  NavigatingInnerGridView(modifier = Modifier.fillMaxSize(), isMuted = false)
}

@Preview(
    device =
        "spec:width=411dp,height=891dp,dpi=420,isRound=false,chinSize=0dp,orientation=landscape")
@Composable
fun NavigatingInnerGridViewLandscapePreview() {
  NavigatingInnerGridView(modifier = Modifier.fillMaxSize(), isMuted = true)
}
