# permanent patches

### 0001-Rename-session-name-to-Cinny-Ubuntu-Touch.patch

This patch renames all occurences of "Cinny Web" with "Cinny Ubuntu Touch", so sessions are labeled correctly to represent a UT Cinny device.

### 0002-Add-credits.patch

This patch adds credits to the original author of cinny click packaging app and the current maintainer to Cinny's about page.

### 0003-Set-push-notifications-to-UTs-push-hook.patch

I admit, I don't really understand what this patch does. But it was implemented for a reason before...

### 0004-disable_cinny_notif_sounds.patch

Cinny will play it's own notification sounds. This can even override silent mode on UT. Also the sound can't be choosen.
Also UT has its own notification sound "magic", so we don't need this "build-in" sound.
Therefore it can be deactivated to make sure we have only UT native notification sounds.

### 0005-Implement-WebChannel-for-qml-communication.patch

This patch implements a QML binding in html code. This way we can call functions in cinny's "website code" that triggers actions in qml files. This allows interaction and is used for things like contenthub integration.

### 0006-Download-images-using-qml-backend.patch
### 0007-Download-files-using-qml-backend.patch
### 0008-Download-pdfpreview-using-qml-backend.patch
### 0010-Download-cinnykeys-using-qml-backend.patch

Those patches implement UT native download-to-content hub functions using #0005.

# temporary patches

### 9001_bump_vite_dependencie.patch

After Cinny release 4.4.0 vite has been bumped, marked as security relevant. So I may as well bump that here until a new version of cinny is released including this bump. Then this patch can be removed.

### 9002_disable_currently_broken_view_pdf.patch

Viewing pdf files directly in Cinny is currently broken on UT only. I am not 100% sure why (there are no helpful error messages), but I guess an incompatibility of the *pdfjs-dist* plugin with our WebEngineView component.
I tried downgrading the plugin to some 3.x version, but that didn't seem to help. So because I currently can't fix it, I am disabling this button to avoid error reports. Downloading works though, so pdf files can be viewed in a native pdf viewer via content hub share.
Hopefully it can be enabled at a later point.