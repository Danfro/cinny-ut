# permanent patches

### 0001-Rename-session-name-to-Cinny-Ubuntu-Touch.patch

This patch renames all occurences of "Cinny Web" with "Cinny Ubuntu Touch", so sessions are labeled correctly to represent a UT Cinny device.

### 0002-Add-credits.patch

This patch adds credits to the original author of cinny click packaging app and the current maintainer to Cinny's about page.

### 0003-Set-push-notifications-to-UTs-push-hook.patch

I admit, I don't fully understand what this patch does. But it was implemented for a reason before... It somehow registers Cinny for our UT push message server.

### 0004-Implement-qml-WebChannel.patch

This patch implements a QML binding in html code. This way we can call functions in cinny's "website code" that triggers actions in qml files. This allows interaction and is used for things like contenthub integration.

### 0006-gestures.patch
### 0007-settings.patch

Implement
- set cinny sound notifications to false as default, since they are handled by UT native notification sounds
- add settings for Kugi's bottom bar gesture

# temporary patches

### 9002_disable_currently_broken_view_pdf.patch

Viewing pdf files directly in Cinny is currently broken on UT only. I am not 100% sure why (there are no helpful error messages), but I guess an incompatibility of the *pdfjs-dist* plugin with our WebEngineView component.
I tried downgrading the plugin to some 3.x version, but that didn't seem to help. So because I currently can't fix it, I am disabling this button to avoid error reports. Downloading works though, so pdf files can be viewed in a native pdf viewer via content hub share.
Hopefully it can be enabled at a later point.

### 9003-connect-to-sync.patch
Rename "Connecting..." in the green bar at the top to "Synchronizing..." until this change is upstreamed.

### 9004-9008
Due to our old WebEndineView we can't use the newest Webassembly features introduced with Cinny 4.7.0, concrete the upgrade of matrix-sdk to 37.5.0.
This set of patches downgrades to matrix-sdk 36.1.0, the highest version not using those features, and applies some hacks to make the app work nonetheless.
With a newer WebEngineView this set of patches can be dropped.