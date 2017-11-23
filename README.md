# RSS checker (Ru)
Уведомление о новом событии, публикуемом в RSS. Например, можно настроить уведомление на выход новой серии сериала.<br>
## Настройка
1. [Загрузите программу уведомлений](https://github.com/r57zone/notifications) и распакуйте её, например, в папку "C:\Program Files\Notification".<br>
2. Изменить путь до программы уведомлений (параметр "NotificationApp"), в файле "Setup.ini", находящийся в папке загруженного "RSS checker". Там же можно изменить интервал проверки RSS лент, по умолчанию раз в 20 минут.<br>
3. (Необязательно) [Загрузите центр уведомлений](https://github.com/r57zone/Notification-center), чтобы не пропустить уведомление, когда вы отходите от компьютера, распаковать её куда-либо и добавить в ярдык автозагрузку ("Пуск" -> "Все программы" -> "Автозагрузка").<br>
4. Добавьте нужные названия и RSS ленты в файл "rss.xml", для примера, в нем уже добавлены две RSS ленты и несколько сериалов для проверки.<br>
5. Добавьте "RSS checker" в автозагрузку.<br>
## Фильтры
Поиск происходит по атрибуту search, например, search="The Americans". В этом случае в событии RSS ленты будет искаться название "The Americans". Искать названия лучше на латинице, чтобы не было проблем с кодировками.<br>
Игнорирование происходит по атрибуту ignore, например, ignore="720p;1080p;". В этом случае будут игнорироваться названия со строками "720p" и "1080p".<br>
Значение параметра "name" необходимо для приложения уведомлений.<br>
## Уведомление
Элемент RSS содержит атрибут "notification", который будет отображаться в уведомлении о новом событии. Также можно добавить иконки в уведомление, для этого необходимо добавить изображения в папку "Icons" программы уведомлений и изменить атрибуты big-icon="1.png" и small-icon="2.png", написав в них названия изображений. Большая иконка имеет размер 90 на 90 пикселей, а маленькая 30 на 30, более подробно можно прочитать [тут](https://github.com/r57zone/notifications).<br> 
## Скриншот
![](https://cloud.githubusercontent.com/assets/9499881/17830407/63166c72-66db-11e6-9665-eaae5361cb34.png)<br>
## Загрузка
>Версия для Windows XP, 7, 8.1, 10.<br>
**[Загрузить](https://github.com/r57zone/RSS-checker/releases)**<br>
## Обратная связь
`r57zone[собака]gmail.com`

# RSS checker (En)
Notification of a new event published in RSS. For example, can set up a notification for the release of a new series of the tv show.<br>
## Setup
1. [Download notification app](https://github.com/r57zone/notifications) and extract him to folder "C:\Program Files\Notification".<br>
2. Change the path to the notification program (parameter "NotificationApp"), in file "Setup.ini", located in the folder of the extracted "RSS checker". In the same place, you can change the interval for checking RSS feeds, the default time is 20 minutes.<br>
3. (Not necessary) [Download notification center](https://github.com/r57zone/Notification-center), for not to skip the notification when you leave the computer, unpack it somewhere and add to the startup ("Start" -> "All Programs" -> "Startup").<br>
4. Add the necessary titles and RSS feeds to the file "rss.xml", for example, it already has two RSS feeds and several serials for verification.<br>
5. Add the "RSS checker" to startup.<br>
## Filters
The search is based on the search attribute, for example, search="The Americans". In this case, the name "The Americans" will be searched for in the RSS feed event.<br>
Ignoring occurs on the ignore attribute, for example, ignore="720p;1080p;". In this case, the names with the lines "720p" and "1080p" will be ignored.<br>
The value of the "name" parameter is required for the notification application.<br>
## Notification
The RSS element contains the "notification" attribute, which will be displayed in the notification of the new event. You can also add icons to the notification by adding images to the "Icons" folder of the notification program and changing the attributes big-icon="1.png" and small-icon="2.png" by writing the image names in them. A large icon has a size of 90 by 90 pixels, and a small one is 30 by 30, you can read more [here](https://github.com/r57zone/notifications).<br> 
## Download
>Version for Windows XP, 7, 8.1, 10.<br>
>If you need a program with an English translation, please write to email and I'll will build it soon.<br>
**[Donwload](https://github.com/r57zone/RSS-checker/releases)**<br>
## Feedback
`r57zone[at]gmail.com`

