v4.10.0
For Cinny changelog please see releases info under https://github.com/cinnyapp/cinny/releases.

Cinny UT changelog:
- updated: Cinny version to 4.10.0
- removed: Cinny-ut 24h setting patch, since Cinny has now an implementation for that
- improved: reworded "Synchronizing..." to "Connecting to account..." since that is apparently what happens

v4.6.0.2
- fixed: blank screen when clicking on notification with cinny already open
- improved: added cinny-ut version number to about page

v4.6.0.1
- improved: building and releasing with github action (but not fully working yet)

v4.6.0
For Cinny changelog please see releases info under https://github.com/cinnyapp/cinny/releases.

Note: With Cinny 4.6.0 user names are now per default colored based on permissions. The previous design can be restored in settings.

Cinny UT changelog:

- added: optional bottom bar for forward/backward navigation (thanks to @kugiigi)
- added: setting for 24h time format
- improved: reworded "Connecting..." to "Synchronizing..."


v4.5.1
For Cinny changelog please see releases info under https://github.com/cinnyapp/cinny/releases.

Cinny UT changelog:
- new maintainer danfro
- updated: Cinny version to 4.5.1
- improved: content hub handling and downloading of files based on mime type
- added: download option for audio files

Known issues:
- pdf view in-app doesn't work, temporarily disabled in this version of Cinny UT
- logging out can hang, please try a second time, it will log out even if the confirmation doesn't show up but only an endless spinner
- signal bridge messages show no message content
- audio files only get a generic name, no original name