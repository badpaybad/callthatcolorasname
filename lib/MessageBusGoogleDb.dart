import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class MessageBusGoogleDb {
  MessageBusGoogleDb._privateConstructor() {}

  static final MessageBusGoogleDb instance =
      MessageBusGoogleDb._privateConstructor();

  Map<String, DateTime> _expiredKeysLocalMemmory = {};

  Future<void> _buildExistedCacheKeys() async {
    try {
      var allData = (await _firebaseDatabase!
              .ref("GoogleMessageBus")
              .child("CacheExpiredList")
              .once())
          .snapshot;

      for (var d in allData.children) {
        var val = d.value as dynamic;
        var k = val["key"] as String;

        if (_expiredKeysLocalMemmory.containsKey(k) == false) {
          var v = DateTime.fromMillisecondsSinceEpoch(
              int.parse(val["expireAt"].toString()));
          //print("_expiredKeysLocalMemmory $k ${val["expireAt"]} v: $v");
          _expiredKeysLocalMemmory[k] = v;
        }
      }
    } catch (ex) {}
  }

  Future<void> SetExpired(String key,
      {int expireAfterMiliseconds = 60000}) async {
    var expiredAt =
        DateTime.now().add(Duration(milliseconds: expireAfterMiliseconds));

    _expiredKeysLocalMemmory[key] = expiredAt;
    try {
      var ref =
          _firebaseDatabase!.ref("GoogleMessageBus/CacheExpiredList/$key");
      ref.set({"key": key, "expireAt": expiredAt.millisecondsSinceEpoch});
    } catch (ex) {}
  }

  Future<void> _eventLoop() async {
    await _buildExistedCacheKeys();
    var t1 = DateTime.now().millisecondsSinceEpoch;
    while (true) {
      var t2 = DateTime.now().millisecondsSinceEpoch;
      if (t2 - t1 > 60000) {
        _buildExistedCacheKeys();
      }
      await Future.delayed(const Duration(milliseconds: 10));

      List<String> keysToRemove = [];

      for (var k in _expiredKeysLocalMemmory.keys) {
        var v = _expiredKeysLocalMemmory[k];
        if (v != null) {
          var t1 = v.millisecondsSinceEpoch;
          var t2 = DateTime.now().millisecondsSinceEpoch;

          if (t2 - t1 > 0) {
            keysToRemove.add(k);
          }
        }
      }

      for (var k in keysToRemove) {
        _expiredKeysLocalMemmory.remove(k);
        try {
          await _firebaseDatabase!.ref("GoogleMessageBus/Caches/$k").remove();
        } catch (ex) {}
      }
    }
  }

  FirebaseApp? _firebaseApp;
  FirebaseDatabase? _firebaseDatabase;
  FirebaseFirestore? _firebaseFirestore;

  bool _isInit = false;

  bool _isInitDone = false;

  Future<void> ensureInit() async {
    while (_isInitDone == false) {
      print(
          "GoogleMessageBus waiting loged to init firebase realtime, firestore services");
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> init(FirebaseApp firebaseApp, FirebaseDatabase firebaseDatabase,
      FirebaseFirestore firebaseFirestore) async {
    if (_isInit) return ensureInit();
    _isInit = true;
    _isInitDone = false;

    _firebaseApp = firebaseApp;
    _firebaseDatabase = firebaseDatabase;
    _firebaseFirestore = firebaseFirestore;

    _isInitDone = true;
    print(
        "_firebaseApp $_firebaseApp _firebaseDatabase $_firebaseDatabase _firebaseFirestore $_firebaseFirestore");

    _eventLoop();
    print("GoogleMessageBus.init: done");
  }

  Future<void> Publish<T>(String key, T data,
      {int setNullAndDelayInMilisec = 0}) async {
    await ensureInit();
    try {
      if (setNullAndDelayInMilisec > 0) {
        await Future.delayed(Duration(milliseconds: setNullAndDelayInMilisec));
        await _firebaseDatabase!
            .ref("GoogleMessageBus/Channels/$key")
            .set(null);
      }
      await _firebaseDatabase!.ref("GoogleMessageBus/Channels/$key").set(data);
    } catch (ex) {
      print("Publish:GoogleMessageBus/Channels/$key Publish.ERR $ex");
    }
  }

  final Map<String, StreamSubscription<DatabaseEvent>> _subscribers =
      <String, StreamSubscription<DatabaseEvent>>{};
  Map<String, DatabaseReference> _databaseRef = {};

  final Map<String, Timer> _subscribersTimer = {};

  Future<void> Subscribe<T>(
      String key, String subName, Future<void> Function(T) onMsg) async {
    await ensureInit();
    try {
      var key_cha_sub = "$key#_#$subName";

      print("key_cha_sub $key_cha_sub");

      var temp = _subscribers[key_cha_sub];

      temp?.cancel();

      var timerSub = _subscribersTimer[key_cha_sub];
      timerSub?.cancel();

      var xChannel = _firebaseDatabase!.ref("GoogleMessageBus/Channels/$key");

      _databaseRef["GoogleMessageBus/Channels/$key"] = xChannel;

      temp = xChannel.onValue.listen((event) async {
        Object? msg2Process = event.snapshot.value;
        if (msg2Process == null) {
          return;
        }
        print("GoogleMessageBus/Channels/$key : $msg2Process");

        try {
          await onMsg(msg2Process as T);
        } catch (ex) {
          print(
              "Subscribe:GoogleMessageBus/Channels/$key Subscribe.ERR $ex \r\n----\r\n$msg2Process");
        }
        try {
          // await xChannel.set(null);
        } catch (ex) {}
      });

      _subscribers[key_cha_sub] = temp;

      // _subscribersTimer[key_cha_sub] =
      //     Timer.periodic(const Duration(seconds: 120), (timer) async {
      //   //todo:recheck for reconnect cause timeout
      //   await Subscribe<T>(key, subName, onMsg);
      // });

    } catch (exsub) {
      await Future.delayed(const Duration(seconds: 2));
      await Subscribe<T>(key, subName, onMsg);
    }
  }

  Future<void> Unsubscribe<T>(String key, String subName) async {
    await ensureInit();
    var key_cha_sub = "$key#_#$subName";
    if (_subscribers[key_cha_sub] != null) {
      await _subscribers[key_cha_sub]?.cancel();
    }
    await _subscribers.remove(key_cha_sub);

    await _firebaseDatabase!.ref("GoogleMessageBus/Channels/$key").set(null);
    print("Unsubscribe: GoogleMessageBus/Channels/$key");
  }

  Future<void> Set<T>(String key, T data,
      {int expireAfterMiliseconds = 60000}) async {
    await ensureInit();
    try {
      await _firebaseDatabase!
          .ref("GoogleMessageBus/Caches/$key")
          .set({"data": data});
    } catch (ex) {
      print("Set:GoogleMessageBus/Channels/$key Set.ERR $ex");
    }
    await SetExpired(key, expireAfterMiliseconds: expireAfterMiliseconds);
  }

  Future<T?> Get<T>(String key) async {
    await ensureInit();
    try {
      print("Get1 $key");
      var temp =
          (await _firebaseDatabase!.ref("GoogleMessageBus/Caches/$key").once())
              .snapshot;

      print("Get2 $key temp: ${temp.children.length}");

      if (temp == null) return null;
      if (temp.value == null) return null;
      var val = temp.value as dynamic;
      return val["data"] as T;
    } catch (ex) {
      print("GoogleMessageBus/Channels/$key Get.ERR $ex");
      return null;
    }
  }

  Future<T> GetOrSet<T>(String key, Future<T> Function() setFunc,
      {int expireAfterMiliseconds = 60000}) async {
    await ensureInit();
    print("GetOrSet $key");
    var temp = await Get<T>(key);

    if (temp == null) {
      temp = await setFunc();
      print("GetOrSet1 $key $temp");
      await Set<T>(key, temp as T,
          expireAfterMiliseconds: expireAfterMiliseconds);
    }

    print("GetOrSet2 $key $temp");

    return temp!;
  }

  Future<void> ListAdd<T>(String key, T val) async {
    await ensureInit();
    try {
      var ref = _firebaseDatabase!.ref("GoogleMessageBus/List/$key/$val");
      await ref.set({"key": val});
      //await ref.push().set({"key": val});
    } catch (ex) {
      print("ListAdd:GoogleMessageBus/Channels/$key ListAdd.ERR $ex");
      return null;
    }
  }

  Future<List<T>> ListGetAll<T>(String key) async {
    await ensureInit();
    try {
      var allData =
          (await _firebaseDatabase!.ref("GoogleMessageBus/List/$key").once())
              .snapshot;

      List<T> temp = [];
      for (var d in allData.children) {
        var val = d.value as dynamic;
        temp.add(val["key"]);
      }

      return temp;
    } catch (ex) {
      print("ListGetAll:GoogleMessageBus/Channels/$key ListGetAll.ERR $ex");
      return [];
    }
  }
}
