[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/r57zone/RSS-checker/blob/master/README.md) 
[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/r57zone/RSS-checker/blob/master/README.EN.md) 
# RSS checker
Уведомление о новом событии, публикуемом в RSS. Например, можно настроить уведомление на выход новой серии сериала и загрузить торрент.

## Настройка
1. [Загрузите программу уведомлений](https://github.com/r57zone/notifications) и распакуйте её, например, в папку "C:\Program Files\Notification".<br>
2. Изменить путь до программы уведомлений (параметр "NotificationApp"), в файле "Setup.ini", находящийся в папке загруженного "RSS checker". Там же можно изменить интервал проверки RSS лент, по умолчанию раз в 20 минут.<br>
3. (Необязательно) [Загрузите центр уведомлений](https://github.com/r57zone/Notification-center), чтобы не пропустить уведомление, когда вы отходите от компьютера, распаковать её куда-либо и добавить в ярдык автозагрузку ("Пуск" -> "Все программы" -> "Автозагрузка").<br>
4. Добавьте нужные названия и RSS ленты в файл "rss.xml", для примера, в нем уже добавлены две RSS ленты и несколько сериалов для проверки.<br>
5. Добавьте "RSS checker" в автозагрузку.<br>
6. (Необязательно) Измените язык в файле "Setup.ini" на русский (изменить параметр Language на "Russian").

## Фильтры
Поиск происходит по атрибуту search, например, search="The Americans". В этом случае в событии RSS ленты будет искаться название "The Americans". Искать названия лучше на латинице, чтобы не было проблем с кодировками.<br>
Игнорирование происходит по атрибуту ignore, например, ignore="720p;1080p;". В этом случае будут игнорироваться названия со строками "720p" и "1080p".<br>
Значение параметра "name" необходимо для приложения уведомлений.<br>
Параметр "download" отвечает за загрузку торрентов (false - нет и true - да). При необходимости можно добавить куки для RSS ленты, параметр "cookie". Для автоматического добавления торрента в программу загрузки необходимо изменить параметр "DownloaderPath" в файле "Setup.ini".

## Уведомление
Элемент RSS содержит атрибут "notification", который будет отображаться в уведомлении о новом событии. Также можно добавить иконки в уведомление, для этого необходимо добавить изображения в папку "Icons" программы уведомлений и изменить атрибуты big-icon="1.png" и small-icon="2.png", написав в них названия изображений. Большая иконка имеет размер 90 на 90 пикселей, а маленькая 30 на 30, более подробно можно прочитать [тут](https://github.com/r57zone/notifications).

## Скриншот
![](https://user-images.githubusercontent.com/9499881/34340035-02dc76d2-e996-11e7-9a6d-71ddb14dbc8d.png)

## Загрузка
>Версия для Windows XP, 7, 8.1, 10.<br>
**[Загрузить](https://github.com/r57zone/RSS-checker/releases)**

## Обратная связь
`r57zone[собака]gmail.com`

