import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/AppContext.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '/MessageBus.dart';
import '/NotificationHelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oktoast/oktoast.dart';
import 'HttpBase.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {

  // TestJsonSeriallizeForMsg().Run();
  WidgetsFlutterBinding.ensureInitialized();
  // DartPluginRegistrant.ensureInitialized();
  await Hive.initFlutter();
  // WebServerApiMvc.instance.start();
  await MessageBus.instance.Init();
  await AppContext.instance.initFirebaseApp();
  await AppContext.instance.init_call_in_void_main();

  // Directory tempDir = await getTemporaryDirectory();
  // String tempPath = tempDir.path;
  //
  // Directory appDocDir = await getApplicationDocumentsDirectory();
  // String appDocPath = appDocDir.path;
  //
  // var cmdR = await Process.run('ip', ['a']);
  // print("--------------------------cmdR: $cmdR");
  // print(cmdR.stdout);
  // print(cmdR.stderr);
  // print(appDocPath);
  // print((await getExternalStorageDirectory() )?.path);
  // print((await getApplicationSupportDirectory() )?.path);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    AppContext.instance.permissionsRequest();

    NotificationHelper.instance.onForgroundNotification((msg) async {
      //_lastMsg = jsonEncode(msg.data);

      NotificationHelper.instance.showNotification(msg);

      //if (mounted) setState(() {});
    });

    AppContext.instance.googleSignInSilently().then((v) async{

      if (mounted) setState(() {});
    });
  }

  Image? _imgTest;

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        builder: (_, Widget? child) => OKToast(child: child!),
        navigatorKey: AppContext.instance.navigatorKey,
        routes: AppContext.instance.routesForNavigator,
        title: 'Flutter boilerplate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SafeArea(
          child: Stack(
            children:  [
              //TestGoogleMlkitPage()
              //ColorDetectionPage()
              Text("hello")
              //WebRtcP2pVideoStreamPageTest()
            ],
          ),
        )
        // SafeArea(
        //     child: Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: [
        //     //AppContextUi(),
        //     //Expanded(child: GoogleSampleUsagePage())
        //     Expanded(child: WebRtcP2pVideoStreamPage())
        //   ],
        // ))
        );
  }
}
