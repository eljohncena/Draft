# Draft
Swift app to call Sleeper.com api for friends fantasy football league. 

End goal is to build IOS, iPadOS and MacOS Widgets in different sizes. Starting with simple ranking on small widgets and ending with being able to display several statistics
of an individuals team on larger widgets (ipadOS and MacOS). Options should include ranking,individual scores, matchups and team stats.

The iPhone app is the data engine: it caches the league and writes rank, record, matchup, and team stats for WidgetKit. Watch gets the same snapshot over WatchConnectivity, and can fetch Sleeper itself if that snapshot is missing or stale on a game day.

Open the app once, mark **That’s me** on your team (or after a username search), then add widgets. Tapping a widget opens the matching screen (`draft://team/…`, `draft://matchup/…`, `draft://standings`). On Thu/Sun/Mon the app schedules a background refresh so widgets can update without a launch. If you set your team, a Live Activity can show the live matchup score on game days.

RoadMap:

- [x] General layout
- [x] Pull weekly scores and mathups
- [x] Store data to reduce amount of calls except on Game Days (Thursday, Sunday, Monday)
- [x] Display Leage scores (Points added weekly and rank)
- [x] Display Players and their stats each that each team own (Season and weekly)
- [x] Add images/avatars for users with no uploaded image in Sleeper.com
- [x] Add accessibility support 
- [x] IOS Widget
    - [x] small
    - [x] medium
    - [x] large
- [x] ipadOS Support
- [x] ipadOS Widget
    - [x] small
    - [x] medium
    - [x] large
    - [x] xlarge
- [x] macOS Support      
- [x] macOS Widget
    - [x] small
    - [x] medium
    - [x] large
    - [x] xlarge
- [x] watchOS Support
- [x] watchOS
    - [x] Complication
    - [x] Smart Stack
- [x] visionOS (Beta) Support


Current UI and work


![Simulator Screenshot - iPhone 14 Pro Max - 2023-09-18 at 02 52 16](https://github.com/eljohncena/Draft/assets/70674723/8372fb24-fe29-445e-a3df-fa8ae77cb3ff)
![Simulator Screenshot - iPhone 14 Pro Max - 2023-09-18 at 02 52 23](https://github.com/eljohncena/Draft/assets/70674723/7dee6a08-068c-4b10-9bd6-50ad253997ed)
