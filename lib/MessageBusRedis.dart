import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import "package:mutex/mutex.dart";
import 'package:redis/redis.dart';

class MessageBusRedis {
  //DI as singleton
  MessageBusRedis._privateConstructor() {}

  static final MessageBusRedis instance = MessageBusRedis._privateConstructor();

  final String CameraTakePicture = "/camera/take/picture";
  final _channel = <String, Map<String, Future<void> Function(dynamic)>>{};
  final _cache = <String, dynamic>{};
  final _cacheExpired = <String, DateTime?>{};
  final _cacheLockerMutex = Mutex();
  RedisConnection? redisConnection;
  Command? redisCommand;
  bool _isRedisInited = false;

  var ensureRedisCommandInit = Completer();

  Future<void> Init() async {
    initRedis();
  }

  //String _redisHost="192.168.4.90";
  String _redisHost = "118.70.117.208";
  int _redisPort = 6379;
  String _redisPwd = "123456";
  int _redisDb = 4;

  Future<void> initRedis() async {
    if (redisCommand != null) {
      try {
        await redisCommand!.send_nothing();
      } catch (ex) {
        _isRedisInited = false;
      }
    }

    if (_isRedisInited) return ensureRedisCommandInit.future;

    _isRedisInited = true;

    try {
      redisConnection ??= RedisConnection();
      redisCommand = await redisConnection!.connect(_redisHost, _redisPort);
      //redisCommand = await redisConnection!.connect('192.168.4.90', 6379);
      var value = await redisCommand!.send_object(["AUTH", _redisPwd]);
      print("RedisConnection($_redisHost:$_redisPort).AUTH: $value");
      value = await redisCommand!.send_object(["SELECT", "$_redisDb"]);
      print(
          "RedisConnection($_redisHost:$_redisPort).SELECT $_redisDb: $value");

      ensureRedisCommandInit.complete();
    } catch (ex) {
      print("REDIS ERR: $ex");
    }

    return ensureRedisCommandInit.future;
  }

  Future<Command?> createRedisCmd() async {
    try {
      var redconn = RedisConnection();
      //redisCommand = await redisConnection!.connect('118.70.117.208', 6379);
      var cmd = await redconn.connect(_redisHost, _redisPort);
      var value = await cmd!.send_object(["AUTH", _redisPwd]);
      print("RedisConnection($_redisHost:$_redisPort).AUTH: $value");
      value = await cmd!.send_object(["SELECT", "4"]);
      print("RedisConnection($_redisHost:$_redisPort).SELECT 4: $value");

      return cmd;
    } catch (ex) {
      print("REDIS ERR: $ex");
      _isRedisInited = false;
      return redisCommand;
    }
  }

  Future<void> Del<T>(String key) async {
    try {
      await ensureRedisCommandInit.future;

      var val1 = await redisCommand?.send_object(["DEL", key]);
    } catch (ex) {
      _isRedisInited = false;
      print("RedisDel ERR: $ex");
    }
  }

  Future<T?> GetOrSet<T>(String key, Future<T> Function() setFuc,
      {int? afterMilisec = 60000}) async {
    var temp = await Get(key);
    if (temp == null) {
      temp = await setFuc();
      await Set(key, temp, afterMilisec: afterMilisec);
    }

    return temp;
  }

  Future<void> Set<T>(String key, T val, {int? afterMilisec = 60000}) async {
    try {
      await ensureRedisCommandInit.future;

      var valjson = "";

      if (T is String && val is String) {
        valjson = val;
      } else {
        valjson = jsonEncode(val);
      }

      await redisCommand?.send_object(["SET", key, valjson]);
      if (afterMilisec != null) {
        await redisCommand?.send_object([
          "EXPIREAT",
          key,
          DateTime.now().millisecondsSinceEpoch + afterMilisec!
        ]);
      }
    } catch (ex) {
      _isRedisInited = false;
      print("RedisSet ERR: $ex");
    }
  }

  Future<T?> Get<T>(String key) async {
    try {
      await ensureRedisCommandInit.future;

      var val = await redisCommand?.send_object(["GET", key]);
      if (val == null) return null;
      try {
        if (T is String) return val;

        val = jsonDecode(val);
        return val;
      } catch (ex) {
        if (T is String) {
          return val;
        }
      }
    } catch (ex) {
      _isRedisInited = false;
      print("RedisSet ERR: $ex");
      return null;
    }
  }

  Future<void> Enqueue<T>(String key, T val) async {
    try {
      await ensureRedisCommandInit.future;

      var jsonData = "";
      if (T is String && val is String) {
        jsonData = val;
      } else {
        jsonData = jsonEncode(val);
      }
      var s3 = DateTime.now().millisecondsSinceEpoch;
      var val1 = await redisCommand?.send_object(["LPUSH", key, jsonData]);
      var s4 = DateTime.now().millisecondsSinceEpoch;

      //print("s2-s1 ${s2-s1} s3-s2 ${s3-s2} s4-s3 ${s4-s3} tt ${s4-s1}");
    } catch (ex) {
      _isRedisInited = false;
      print("RedisSet ERR: $ex");
    }
  }

  Future<T?> Dequeue<T>(String key) async {
    try {
      await ensureRedisCommandInit.future;

      var val = await redisCommand?.send_object(["ROP", key]);
      if (T is String) return val;

      return jsonDecode(val);
    } catch (ex) {
      _isRedisInited = false;
      print("RedisDequeue ERR: $ex");
      return null;
    }
  }

  Future<List<T>> ListGetAll<T>(String key, {int start = 0, int? stop}) async {
    try {
      await ensureRedisCommandInit.future;
      stop ??= 9999999999900;

      var val = await redisCommand?.send_object(["LRANGE", key, start, stop]);

      print("RedisListGetAll: $key : $val");
      if (val == null) return [];

      var temp = val as List<dynamic>;

      print(temp);

      List<T> r = [];
      List<String> rs = [];

      for (var t in temp) {
        if (T is String && t is String) {
          rs.add(t);
        } else {
          r.add(jsonDecode(t));
        }
      }

      if (T is String) return rs as List<T>;

      return r;
    } catch (ex) {
      _isRedisInited = false;
      print("RedisListGetAll ERR: $ex");
      return [];
    }
  }

  Future<void> ListAdd<T>(String key, T val) async {
    try {
      await ensureRedisCommandInit.future;
      var jsonData = "";
      if (T is String && val is String) {
        jsonData = val;
      } else {
        jsonData = jsonEncode(val);
      }
      var val1 = await redisCommand?.send_object(["LPUSH", key, jsonData]);
    } catch (ex) {
      _isRedisInited = false;
      print("RedisListAdd ERR: $ex");
    }
  }

  Future<void> ListRemove(String key, int idx) async {
    try {
      await ensureRedisCommandInit.future;
      throw Exception("Not implement RedisListRemove");
    } catch (ex) {
      _isRedisInited = false;
    }
  }

  Map<String, Command?> _redisListCmdForSubcribe = {};
  Map<String, PubSub?> _redisListPubSubForSubcribe = {};

  Future<void> Unsubscribe(String channelKey, String subscriberName) async {
    await ensureRedisCommandInit.future;

    var keyToUnSub = "$channelKey#_#$subscriberName";

    _redisListPubSubForSubcribe[keyToUnSub]?.unsubscribe([subscriberName]);
    _redisListCmdForSubcribe.remove(keyToUnSub);
    _redisListPubSubForSubcribe.remove(keyToUnSub);
  }

  Future<void> Publish<T>(String channelKey, T val) async {
    try {
      await ensureRedisCommandInit.future;
      var jsonData = "";
      if (T is String && val is String) {
        jsonData = val;
      } else {
        jsonData = jsonEncode(val);
      }
      await redisCommand?.send_object(["PUBLISH", channelKey, jsonData]);
    } catch (ex) {
      _isRedisInited = false;
      print("RedisPub ERR: $ex");
    }
  }

  Future<void> Subscribe<T>(String channelKey, String subscriberName,
      Future Function(T) handle) async {
    try {
      await ensureRedisCommandInit.future;

      var keyToUnSub = "$channelKey#_#$subscriberName";

      if (_redisListPubSubForSubcribe[keyToUnSub] != null) return;

      var cmd = _redisListCmdForSubcribe[keyToUnSub];
      cmd ??= await createRedisCmd();
      _redisListCmdForSubcribe[keyToUnSub] = cmd;

      var pubsub = _redisListPubSubForSubcribe[keyToUnSub];
      pubsub ??= PubSub(cmd!);
      pubsub.subscribe([channelKey]);

      final stream = pubsub.getStream();

      stream.listen((event) {

        print("RedisSub: chanel: $channelKey");
        print("sub: $subscriberName event: $event");
        print("event: $event");
        var typeEvt = event[0].toString();
        print("typeEvt: $typeEvt");

        if (typeEvt != "message") {
          return;
        }

        var eventData = event[2];
        try {
          if (T is String && eventData is String) {
            handle(eventData as dynamic);
          } else {
            var jsonData = jsonDecode(eventData);
            handle(jsonData);
          }
        } catch (exh) {
          print("RedisSub ERR Handle: $exh");
        }
      });
    } catch (ex) {
      _isRedisInited = false;
      print("RedisSub ERR: $ex");
    }
  }
}
