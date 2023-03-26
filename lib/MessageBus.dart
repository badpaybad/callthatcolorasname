import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import "package:mutex/mutex.dart";
import 'package:redis/redis.dart';


class MessageBus {
  //DI as singleton
  MessageBus._privateConstructor() {
    _eventLoop();
  }

  static final MessageBus instance = MessageBus._privateConstructor();
  final String CameraTakePicture = "/camera/take/picture";
  final _channel = <String, Map<String, Future<void> Function(dynamic)>>{};
  final _cache = <String, dynamic>{};
  final _cacheExpired = <String, DateTime?>{};
  final _cacheLockerMutex = Mutex();

  Future<void> Init() async {
      //await MessageBusRedis.instance.initRedis();
  }

  Future<bool> Set<T>(String key, T val, {int? afterMilisec = 60000}) async {
    try {
      await _cacheLockerMutex.acquire();

      var dtnow = DateTime.now();
      _cache[key] = val;

      if (afterMilisec != null) {
        _cacheExpired[key] = dtnow.add(Duration(milliseconds: afterMilisec!));
      } else {
        //never expired
        _cacheExpired[key] = null;
      }
      return true;
    } finally {
      _cacheLockerMutex.release();
    }
  }

  Future<T?> Get<T>(String key) async {
    try {
      await _cacheLockerMutex.acquire();

      if (_cache.containsKey(key) == false) return null;
      return _cache[key] as T;
    } finally {
      _cacheLockerMutex.release();
    }
  }

  Future<T> GetOrSet<T>(String key, Future<T> Function() setFuc,
      {int? afterMilisec = 60000}) async {
    var temp = await Get<T>(key);
    if (temp != null) return temp;

    temp = await setFuc();
    Set(key, temp, afterMilisec: afterMilisec);

    return temp!;
  }

  Future<void> _eventLoop() async {
    while (true) {
      try {
        await _cacheLockerMutex.acquire();

        var dtnow = DateTime.now().microsecondsSinceEpoch;
        List<String> keysExp = [];
        for (var k in _cacheExpired.keys) {
          var dt = _cacheExpired[k];
          if (dt == null) continue;
          if (dt!.microsecondsSinceEpoch < dtnow) {
            keysExp.add(k);
          }
        }
        for (var k in keysExp) {
          _cacheExpired.remove(k);
          _cache.remove(k);
          //print("MessageBuss._cache.remove: $k");
        }
      } finally {
        _cacheLockerMutex.release();
      }

      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  final _queueMap = Map<String, Queue<dynamic>>();
  final _queueLockerMutex = Mutex();

  Future<bool> Enqueue<T>(String queueName, T data, {limitTo: 1000}) async {
    try {
      var getLock = await _queueLockerMutex.acquire();
      //if (getLock == null) return false; //some how can not talk to cpu get lock

      //if (_queueLocker == true) return false;

      if (_queueMap.containsKey(queueName) == false) {
        _queueMap[queueName] = Queue<dynamic>();
      }
      var qlen = _queueMap[queueName]?.length ?? 0;
      if (qlen > limitTo) {
        //prevent stuck queue or over ram consume
        var toRemove = qlen - limitTo;
        for (var i = 0; i < toRemove; i++) {
          _queueMap[queueName]?.removeFirst();
        }
      }

      _queueMap[queueName]?.add(data);
      return true;
    } finally {
      _queueLockerMutex.release();
    }
  }

  Future<T?> Dequeue<T>(String queueName) async {
    try {
      var getLock = await _queueLockerMutex.acquire();

      if (_queueMap.containsKey(queueName) == false) {
        _queueMap[queueName] = Queue<dynamic>();
      }

      var qlen = _queueMap[queueName]?.length ?? 0;
      if (qlen == 0) return null;

      T itm = _queueMap[queueName]?.first;
      _queueMap[queueName]?.remove(itm);
      return itm;
    } finally {
      _queueLockerMutex.release();
    }
  }

  Future<void> Subscribe(String channelName, String subscriberName,
      Future<void> Function(dynamic) handle) async {
    if (_channel.containsKey(channelName) == false) {
      _channel[channelName] = <String, Future<void> Function(dynamic)>{};
    }
    _channel[channelName]?[subscriberName] = handle;
  }

  Future<void> Unsubscribe(String channelName, String subscriberName) async {
    _channel[channelName]!.remove(subscriberName);
  }

  Future<void> ClearChannel(String channelName) async {
    _channel.remove(channelName);
  }

  Future<void> Publish(String channelName, dynamic data) async {
    if (_channel.containsKey(channelName) == false) {
      _channel[channelName] = <String, Future<void> Function(dynamic)>{};
    }
    for (var h in _channel[channelName]!.values) {
      h(data);
    }
  }
}
