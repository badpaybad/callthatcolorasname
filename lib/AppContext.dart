import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '/NotificationHelper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MessageBusGoogleDb.dart';
import 'package:flutter/services.dart' show rootBundle;


//https://firebase.google.com/docs/cloud-messaging/android/first-message
//https://firebase.google.com/docs/flutter/setup?platform=ios
//https://firebase.google.com/docs/flutter/setup?platform=ios#available-plugins

//https://github.com/firebase/flutterfire/blob/master/packages/firebase_messaging/firebase_messaging/example/lib/main.dart

class AppContext {
  AppContext._privateConstructor() {}

  static final AppContext instance = AppContext._privateConstructor();

  GoogleSignInAccount? googleCurrentUser;

  String? appBearerToken;

  String? appFcmToken;

//https://developers.google.com/android/guides/client-auth
  final GoogleSignIn appGoogleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      // "https://www.googleapis.com/auth/cloud-platform"
      //'openid',
      //'profile',
      //'https://www.googleapis.com/auth/contacts',
      //'https://www.googleapis.com/auth/contacts.readonly',
      //'https://www.googleapis.com/auth/datastore',
      //'https://www.googleapis.com/auth/firebase.messaging'
    ],
  );

  FirebaseApp? firebaseApp;
  FirebaseDatabase? firebaseDb;
  FirebaseAuth? firebaseAuth;

  FirebaseFirestore? fireStoreDb;

  Map<String, WidgetBuilder> routesForNavigator = <String, WidgetBuilder>{};

  Future<Uint8List> getImage(String key) async {
    return (await rootBundle.load(key)).buffer.asUint8List();
  }

  void permissionsRequest() {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      [
        Permission.accessMediaLocation,
        Permission.camera,
        //Permission.audio,
        // Permission.bluetooth,
        // Permission.bluetoothAdvertise,
        // Permission.bluetoothConnect,
        // Permission.bluetoothScan,
        // Permission.location,
        Permission.ignoreBatteryOptimizations,
        //Permission.accessNotificationPolicy,
        Permission.notification,
        Permission.mediaLibrary,
        // Permission.microphone,
        //Permission.manageExternalStorage,
        Permission.storage,
        //add more permission to request here.
      ].request().then((statuses) async {
        // var isDenied =
        //     statuses.values.any((p) => (p.isDenied || p.isPermanentlyDenied
        //         //||
        //         //p.isLimited ||
        //         //p.isRestricted
        //         ));
        // if (isDenied) {
        String temp = "";
        for (var pk in statuses.keys) {
          temp = "$temp\r\n$pk: ${statuses[pk]}";
        }
        print(temp);
        //
        //   showToast(
        //       "You have allow access microphone and storage, quiting ...\r\n\r\nIf you see message again and again should re-install application\r\nThen allow permission to access microphone and storage",
        //       duration: const Duration(seconds: 5),
        //       textAlign: TextAlign.left);
        //   await Future.delayed(const Duration(seconds: 5));
        //   try {
        //     if (mounted) Navigator.of(context).pop();
        //   } catch (ex) {}
        //   try {
        //     if (mounted) SystemNavigator.pop();
        //   } catch (ex) {}
        // }
      });
    }
  }

  final String screenNameLiveStream = "/LiveStream";
  final String screenNameUiPermission = "/PermissionsUi";
  final String screenNameFaceDefinitionRegister = "/FaceDefinitionRegister";
  final String screenNameColorDetection = "/ColorDetection";

  Future<void> init_call_in_void_main() async {
    //todo: mapping your widget with router key for navigate, eg: noti onTab show screen
    AppContext.instance.routesForNavigator.addAll({

      // AppContext.instance.screenNameColorDetection: (BuildContext ctx) =>
      //     ColorDetectionPage(),
    });

    initFirebaseApp().then((value) async {
      await NotificationHelper.instance.init();

      appGoogleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        googleCurrentUser = account;
        if (googleCurrentUser != null) {
          await _initOtherGoogleServicesWithGoogelAcc(googleCurrentUser!);
        }
      });
    });
  }

  Future<void> openScreenHome() async {
    //Navigator.of(context).popUntil(ModalRoute.withName('/'));
    //AppContext.instance.navigatorKey.currentState?.popUntil(ModalRoute.withName("/"));
    var screenName = AppContext.instance.screenNameLiveStream;
    await AppContext.instance.openScreen(screenName);
  }

  Map<String, bool> _screenOpening = {};

  Future<void> openScreen(String screenName) async {
    if (_screenOpening[screenName] != null) return;

    _screenOpening[screenName] = true;
    debugPrint("openScreen: ${screenName}");


    await AppContext.instance.navigatorKey.currentState
        ?.pushReplacementNamed(screenName);

    await Future.delayed(const Duration(seconds: 2));

    _screenOpening.remove(screenName);
  }

  bool _isInitFirebaseApp = false;
  bool _isInitFirebaseApp_done = false;

  Future<void> ensureInitFirebaseApp() async {
    while (_isInitFirebaseApp_done == false) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> initFirebaseApp() async {
    try {
      if (_isInitFirebaseApp == true) return ensureInitFirebaseApp();
      _isInitFirebaseApp = true;

      print("Firebase.initializeApp for DEFAULT");

      //firebaseApp = await Firebase.initializeApp();

      String firebaseAppName = "[DEFAULT]";
      firebaseApp = await Firebase.initializeApp(
          name: firebaseAppName,
          options: const FirebaseOptions(
              apiKey: "AIzaSyBwsIOZ9nZAuypco7ERdCVM74RMF_dK8Xo",
              appId: "1:787425357847:android:1254a620eece9509a92c52",
              messagingSenderId: "787425357847",
              projectId: "realtimedbtest-d8c6b",
              databaseURL:
                  'https://realtimedbtest-d8c6b-default-rtdb.asia-southeast1.firebasedatabase.app',
              storageBucket: 'realtimedbtest-d8c6b.appspot.com'));

      _isInitFirebaseApp_done = true;

      print("Firebase.initializeApp for EnglishScript");
    } catch (ex) {
      print("initFirebaseApp ERR: $ex");
      _isInitFirebaseApp = false;
      await Future.delayed(const Duration(seconds: 1));
      await initFirebaseApp();
    }
  }

  GlobalKey<NavigatorState> navigatorKey =
      GlobalKey(debugLabel: "Main Navigator");

  Future<void> googleSignInSilently() async {
    await initFirebaseApp();

    while (googleCurrentUser == null) {
      googleCurrentUser = await appGoogleSignIn.signInSilently();

      googleCurrentUser ??= await appGoogleSignIn.signIn();

      await Future.delayed(const Duration(seconds: 1));
    }

    if (googleCurrentUser != null) {
      await _initOtherGoogleServicesWithGoogelAcc(googleCurrentUser!);
    }

    _getValFromJsonString(String key, String json) {
      var temp = json.trim().replaceAll(" ", " ").replaceAll("'", "\"");
      temp = temp = json.trim().replaceAll(": ", ":");
      temp = temp = json.trim().replaceAll(" :", ":");
      var tempKey = "\"${key}\":\"";
      var idx = json.indexOf(tempKey);
      if (idx < 0) return "";
      var subtemp = temp.substring(idx + tempKey.length);
      idx = subtemp.indexOf("\"");
      subtemp = subtemp.substring(0, idx);

      return subtemp;
    }


  }

  Future<void>
      _initOtherGoogleServicesWithCustomTokenFromLoginToServer() async {
    print("_initOtherGoogleServicesWithGoogelAcc 1");
    //todo: if you dont want use google login, use your server, you need custom token from server use firebase admin to generate
    //_firebaseAuth!.signInWithCustomToken(token_custom);
    //todo: need firebase admin from server to generate custom token
  }

  bool _isInitOtherGoogleSevices = false;

  Future<void> _initOtherGoogleServicesWithGoogelAcc(
      GoogleSignInAccount acc) async {
    if (_isInitOtherGoogleSevices) return;
    _isInitOtherGoogleSevices = true;

    firebaseAuth = FirebaseAuth.instanceFor(
        app: firebaseApp!, persistence: Persistence.LOCAL);

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleCurrentUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    print("_initOtherGoogleServicesWithGoogelAcc 2");
    //to access other firebase services
    var authorized = await firebaseAuth!.signInWithCredential(credential);

    print("_initOtherGoogleServicesWithGoogelAcc 3");

    print(firebaseAuth?.currentUser?.displayName);
    print(authorized);

    firebaseDb = FirebaseDatabase.instanceFor(
        app: firebaseApp!,
        databaseURL:
            "https://realtimedbtest-d8c6b-default-rtdb.asia-southeast1.firebasedatabase.app");

    print("_initOtherGoogleServicesWithGoogelAcc 4");
    fireStoreDb = FirebaseFirestore.instanceFor(app: firebaseApp!);

    print("_initOtherGoogleServicesWithGoogelAcc 5");
    await MessageBusGoogleDb.instance
        .init(firebaseApp!, firebaseDb!, fireStoreDb!);

    print("_initOtherGoogleServicesWithGoogelAcc 6");
  }

  Future<void> googleSignOut() async {
    await initFirebaseApp();

    await appGoogleSignIn.disconnect();
    googleCurrentUser = null;
  }

  Future<void> googleSignIn() async {
    try {
      await initFirebaseApp();

      var tempAcc = await appGoogleSignIn.signIn();
      if (tempAcc != null) {
        googleCurrentUser = tempAcc;

        await _initOtherGoogleServicesWithGoogelAcc(googleCurrentUser!);
      }

      var tmptoken = await NotificationHelper.instance.getFcmToken();
      if (tmptoken != null) {
        appFcmToken = tmptoken;
      }
    } catch (error) {
      print(error);
    }
  }

  Future<Map<String, dynamic>> _handleGetContact(
      GoogleSignInAccount user) async {
    final http.Response response = await http.get(
      Uri.parse('https://people.googleapis.com/v1/people/me/connections'
          '?requestMask.includeField=person.names'),
      headers: await user.authHeaders,
    );
    if (response.statusCode != 200) {
      print('People API ${response.statusCode} response: ${response.body}');
      return Map<String, dynamic>();
    }
    final Map<String, dynamic> data = json.decode(response.body);
    //final String? namedContact = _pickFirstNamedContact(data);
    return data;
  }

  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic contact) => contact['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    if (contact != null) {
      final Map<String, dynamic>? name = contact['names'].firstWhere(
        (dynamic name) => name['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      if (name != null) {
        return name['displayName'] as String?;
      }
    }
    return null;
  }

  Future<void> testFirebase() async {
    DatabaseReference dbTestRef = firebaseDb!.ref("fluttertest");

    dbTestRef.onValue.listen((event) async {
      print("dbTestRef event.snapshot.value");
      print(event.snapshot.value);
    });

    // //
    // // dbTestRef.onValue.listen((event) async {
    // //   print("dbTestRef event.snapshot.value");
    // //   print(event.snapshot.value);
    // // });
    //
    // /*{ firebase realtimedb
    //   "rules": {
    //     ".read":"auth.uid != null",
    //     ".write":"auth.uid != null"
    //   }
    // }*/
    // //https://pub.dev/packages/cloud_firestore/example
    // await dbTestRef.set({"name": "du ${DateTime.now().toIso8601String()}"});
    //
    print(
        "(await dbTestRef.get()).value ${(await dbTestRef.once()).snapshot.value}");
/*{ firebase realtimedb
  "rules": {
    ".read":"auth.uid != null",
    ".write":"auth.uid != null"
  }
}*/
    //https://pub.dev/packages/cloud_firestore/example
    await dbTestRef.set({"name": "du ${DateTime.now().toIso8601String()}"});
    //await FirebaseFirestore.instance.terminate();
    //await FirebaseFirestore.instance.clearPersistence();

    final collectionFirestore =
        FirebaseFirestore.instance.collection('firestore-test-app');

    collectionFirestore.snapshots().listen((event) async {
      print(
          "dbFirestoreTest event------------------------- ${event.docs.toList()} ");
    });

    var docFirestore = collectionFirestore.doc("doc_id");

    docFirestore.snapshots().listen((event) async {
      print("docFirestore event------------------------- ${event.data()}");
    });

    docFirestore.set({
      "name": "doc name 1",
      "id": "doc_id ${DateTime.now().toIso8601String()}"
    });

    var objFirestoreAdded = await collectionFirestore.add({
      "name": "doc name 2",
      "id": "doc_id ${DateTime.now().toIso8601String()}"
    });

    print("objFirestoreAdded $objFirestoreAdded");

    var temp = await collectionFirestore.get();
    print("collectionFirestore.get()");
    for (var t in temp.docs) {
      print(t);
    }
  }
}
