import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _messageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _showNotification(message);
}

Future<void> _showNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  String? type = message.data['type'];

  if (notification != null && android != null) {
    AndroidNotificationDetails androidDetails;
    if (type == 'important') {
      androidDetails = AndroidNotificationDetails(
        'important_channel',
        'Important Notifications',
        channelDescription: 'This channel is for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        color: Colors.red,
        playSound: true,
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        'regular_channel',
        'Regular Notifications',
        channelDescription: 'This channel is for regular notifications.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Colors.blue,
        playSound: false,
      );
    }

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: 'Notification Payload',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print('Notification payload: ${response.payload}');
    },
  );

  FirebaseMessaging.onBackgroundMessage(_messageHandler);

  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  String? notificationText;

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;

    _requestPermissions();

    messaging.subscribeToTopic("messaging");

    messaging.getToken().then((value) {
      print("FCM Token: $value");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("Message received in foreground");
      print("Title: ${event.notification?.title}");
      print("Body: ${event.notification?.body}");
      print("Data: ${event.data}");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(event.notification?.title ?? "Notification"),
            content: Text(event.notification?.body ?? ""),
            actions: [
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );

      _showNotification(event);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
    });
  }

  void _requestPermissions() {
    messaging
        .requestPermission(
      alert: true,
      badge: true,
      sound: true,
    )
        .then((settings) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    String? type = message.data['type'];

    if (notification != null) {
      AndroidNotificationDetails androidDetails;
      if (type == 'important') {
        androidDetails = AndroidNotificationDetails(
          'important_channel',
          'Important Notifications',
          channelDescription: 'This channel is for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.red,
          playSound: true,
        );
      } else {
        androidDetails = AndroidNotificationDetails(
          'regular_channel',
          'Regular Notifications',
          channelDescription: 'This channel is for regular notifications.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Colors.blue,
          playSound: false,
        );
      }

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: 'Notification Payload',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(child: Text("Messaging Tutorial")),
    );
  }
}
