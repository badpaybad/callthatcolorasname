import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/AppContext.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:oktoast/oktoast.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  //await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
  await AppContext.instance.initFirebaseApp();
  print(
      "---- Handling a background message: AppContext.instance.initFirebaseApp()");

  var msg = jsonEncode(message.data);
  print(msg);
  print(
      "---- Handling a background message: _do_when_use_touch_tab_into_notification_showed");
  //
  // var routeName = AppContext.instance.routesForNavigator.keys.first;
  //
  // AppContext.instance.navigatorKey.currentState
  //     ?.pushNamed(routeName, arguments: {
  //   "test":
  //   "AppContext.instance.navigatorKey.currentState?.pushNamed(routeName",
  //   "msg": msg
  // });

  NotificationHelper.instance.showNotification(message);
}

Future<void> _do_when_use_touch_tab_into_notification_showed(
    NotificationResponse msg) async {
  if (AppContext.instance.routesForNavigator.keys.length > 0) {
    //todo: base on msg then find route matching
    var routeName = AppContext.instance.routesForNavigator.keys.first;

    // AppContext.instance.navigatorKey.currentState
    //     ?.pushNamed(routeName, arguments: {
    //   "test":
    //       "AppContext.instance.navigatorKey.currentState?.pushNamed(routeName",
    //   "msg": msg
    // });

    showToast("todo: base on msg then find route matching to navigate: $msg ");

    // get args in method build (ContextBuilder context){
    // final args = ModalRoute.of(context)!.settings.arguments as dynamic;
  }
}

class NotificationHelper {
  static const String appIcon = "@mipmap/ic_launcher_adaptive_fore";

  // single color and should be .png
  static const String notifySmallIcon = "@mipmap/ic_launcher_adaptive_fore";

  static const String notifyLagerIcon = "@drawable/notification_icon";

  NotificationHelper._privateConstructor() {}

  static final NotificationHelper instance =
      NotificationHelper._privateConstructor();

  static const AndroidInitializationSettings _initializationSettingsAndroid =
      AndroidInitializationSettings(notifySmallIcon);

  /// Create a [AndroidNotificationChannel] for heads up notifications
  static const AndroidNotificationChannel _channelAndroid =
      AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
    //enableLights: true,
    //ledColor: Colors.orange
  );

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static InitializationSettings initializationSettings =
      const InitializationSettings(
    //iOS: initializationSettingsIOS,
    android: _initializationSettingsAndroid,
  );

  var _is_setupNotifications = false;

  Future<void> _setupNotifications(
      Future<void> Function(NotificationResponse)
          topFunctionDoWhenUseTouchTabIntoNotificationShowed) async {
    if (_is_setupNotifications == true) {
      return;
    }
    _is_setupNotifications = true;

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          topFunctionDoWhenUseTouchTabIntoNotificationShowed,
      onDidReceiveNotificationResponse:
          topFunctionDoWhenUseTouchTabIntoNotificationShowed,
      //onSelectNotification: topFunctionDoWhenUseTouchTabIntoNotificationShowed
    );

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channelAndroid);

    print("NotificationHelper._flutterLocalNotificationsPlugin");

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    print("NotificationHelper.setForegroundNotificationPresentationOptions");

    var token = await getFcmToken();
    print("---- Token device id: ----\r\n$token\r\n----");

    FirebaseMessaging.instance?.onTokenRefresh?.listen((fcmTokenNew) async {
      // TODO: If necessary send token to application server.
      fcmToken = await FirebaseMessaging.instance.getToken();
      print("---- _fcmToken refresh");
      print(fcmTokenNew);
      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    }).onError((err) {
      // Error getting token.
    });

    // NotificationSettings settings = await  FirebaseMessaging.instance.requestPermission(
    //   alert: true,
    //   announcement: true,
    //   badge: true,
    //   carPlay: true,
    //   criticalAlert: true,
    //   provisional: true,
    //   sound: true,
    // );
    //
    // var recheckSettings = await FirebaseMessaging.instance.getNotificationSettings();
    //
    // print("---User granted permission:");
    // print('${recheckSettings?.authorizationStatus??""}');
  }

  bool _is_init_call_in_void_main = false;

  bool _is_init_call_in_void_main_done = false;

  Future<void> ensureInit() async {
    while (_is_init_call_in_void_main_done == false) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  StreamController<dynamic> state = StreamController<dynamic>.broadcast();

  Future<void> init() async {
    try {
      if (_is_init_call_in_void_main == true) return ensureInit();
      _is_init_call_in_void_main = true;

      print("---- NotificationHelper.init_call_in_void_main");

      AppContext.instance.initFirebaseApp().then((value) async {
        await AppContext.instance.ensureInitFirebaseApp();

        print("---- NotificationHelper.init...");

        FirebaseMessaging.instance.app = AppContext.instance.firebaseApp!;

        await NotificationHelper.instance._setupNotifications(
            _do_when_use_touch_tab_into_notification_showed);

        print(
            "----registered: NotificationHelper._do_when_use_touch_tab_into_notification_showed");

        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        print(
            "----registered: NotificationHelper._firebaseMessagingBackgroundHandler");

        var tokenDeviceid = await getFcmToken();
        //print("----tokenDeviceid: $tokenDeviceid");
        state.add({"state": "initDone", "data": tokenDeviceid});

        _is_init_call_in_void_main_done = true;
      });
    } catch (ex) {
      print("init_call_in_void_main ERR: $ex");

      _is_init_call_in_void_main = false;
      await Future.delayed(const Duration(seconds: 2));
      await init();
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (!kIsWeb) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        jsonEncode(message.data),
        jsonEncode(message.data),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelAndroid.id,
            _channelAndroid.name,
            channelDescription: _channelAndroid.description,
            // TODO add a proper drawable resource to android, for now using
            //      one that already exists in example app.
            icon: notifySmallIcon,
            //colorized: true,
            color: Colors.orange,
            largeIcon: const DrawableResourceAndroidBitmap(notifyLagerIcon),
          ),
        ),
      );
    }
  }

  String? fcmToken;

  Future<String?> getFcmToken() async {
    // // //https://firebase.flutter.dev/docs/messaging/usage/

    fcmToken = await FirebaseMessaging.instance.getToken();

    return fcmToken ?? "";
  }

  bool _isForgroundRegister = false;

  Future<void> onForgroundNotification(
      Future<void> Function(RemoteMessage) handle) async {
    if (_isForgroundRegister == true) {
      print(
          "---- onForgroundNotification: WARNING : called somewhere, should call one time in main");
    }
    _isForgroundRegister = true;
    FirebaseMessaging.onMessage?.listen((RemoteMessage message) async {
      await init();
      print('---- Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      handle(message);
    });
  }
}
