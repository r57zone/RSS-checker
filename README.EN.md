[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/r57zone/RSS-checker/blob/master/README.md) 
[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/r57zone/RSS-checker/blob/master/README.EN.md) 
# RSS checker
Notification of a new event published in RSS. For example, can set up a notification for the release of a new series of the tv show and download torrent.

## Setup
1. [Download notification app](https://github.com/r57zone/notifications) and extract him to folder "C:\Program Files\Notification".<br>
2. Change the path to the notification program (parameter "NotificationApp"), in file "Setup.ini", located in the folder of the extracted "RSS checker". In the same place, you can change the interval for checking RSS feeds, the default time is 20 minutes.<br>
3. (Not necessary) [Download notification center](https://github.com/r57zone/Notification-center), for not to skip the notification when you leave the computer, unpack it somewhere and add to the startup ("Start" -> "All Programs" -> "Startup").<br>
4. Add the necessary titles and RSS feeds to the file "rss.xml", for example, it already has two RSS feeds and several serials for verification.<br>
5. Add the "RSS checker" to startup.

## Filters
The search is based on the search attribute, for example, search="The Americans". In this case, the name "The Americans" will be searched for in the RSS feed event.<br>
Ignoring occurs on the ignore attribute, for example, ignore="720p;1080p;". In this case, the names with the lines "720p" and "1080p" will be ignored.<br>
The value of the "name" parameter is required for the notification application.<br>
The parameter "download" is responsible for downloading torrents (false - no and true - yes). If necessary, you can add cookies for RSS feeds, the parameter "cookie". To automatically add a torrent to the boot program, you must change the "DownloaderPath" parameter in the "Setup.ini" file.

## Notification
The RSS element contains the "notification" attribute, which will be displayed in the notification of the new event. You can also add icons to the notification by adding images to the "Icons" folder of the notification program and changing the attributes big-icon="1.png" and small-icon="2.png" by writing the image names in them. A large icon has a size of 90 by 90 pixels, and a small one is 30 by 30, you can read more [here](https://github.com/r57zone/notifications). 

## Screenshot
![](https://user-images.githubusercontent.com/9499881/34340035-02dc76d2-e996-11e7-9a6d-71ddb14dbc8d.png)<br>

## Download
>Version for Windows XP, 7, 8.1, 10.<br>
**[Donwload](https://github.com/r57zone/RSS-checker/releases)**

## Feedback
`r57zone[at]gmail.com`

