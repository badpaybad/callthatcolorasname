import 'dart:typed_data';
import 'dart:io';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import 'package:flutter/services.dart' show rootBundle;

class DataChangeNotifier<T> extends ChangeNotifier {
  T? _data;

  T? get data => _data;

  DataChangeNotifier() {}

  Future<void> subscribe(Future<void> Function(T) handle) async {
    addListener(() async {

      if (_data != null) handle(_data!);
    });
  }

  Future<void> publish(T newData) async {
    _data = newData;
    notifyListeners();
  }
}

class ImageFromSource extends StatefulWidget {
  String _source = "";
  double? _w;
  double? _h;
  Stack? _stack;

  ImageFromSource(String src, {double? w, double? h, Stack? stacks, super.key})
      : _source = src,
        _w = w,
        _h = h,
        _stack = stacks;

  //
  @override
  State<StatefulWidget> createState() {
    return ImageFromSourceState(_source, _w, _h, _stack);
  }
//
// @override
// Widget build(BuildContext context) {
//   var temp = _source.toLowerCase().trim();
//
//   if (temp.startsWith("@")) {
//     return Image.asset(_source.substring(1));
//   }
//   if (temp.startsWith("http:")) {
//     return Image.network(_source);
//   }
//   if (temp.startsWith("https:")) {
//     return Image.network(_source);
//   }
//
//   return Image.file(File(_source));
// }
}

class ImageFromSourceState extends State<ImageFromSource> {
  String _source = "";

  Stack? _stack;
  double? _w;
  double? _h;

  ImageFromSourceState(String src, double? w, double? h, Stack? stacks)
      : _source = src,
        _w = w,
        _h = h,
        _stack = stacks;

  Stack? _stackMain;

  @override
  Widget build(BuildContext context) {
    if (_stack != null) {
      _stackMain = Stack(
        key: UniqueKey(),
        alignment: Alignment.topLeft,
        fit: StackFit.passthrough,
        children: [],
      );
      _stackMain!.children.add(_buildImg());

      _stackMain!.children.addAll(_stack!.children);

      if (_down != null && _up != null && _move != null) {
        _stackMain!.children.add(Positioned(
            left: _down!.dx,
            top: _down!.dy,
            width: _up!.dx - _down!.dx,
            height: _up!.dy - _down!.dy,
            child: Container(
                padding: EdgeInsets.all(0),
                margin: EdgeInsets.all(0),
                decoration: BoxDecoration(
                    color: Color.fromARGB(100, 0, 0, 255),
                    border: Border.all(color: Colors.blue)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: IconButton(
                          padding: EdgeInsets.all(0.0),
                          iconSize: 14,
                          onPressed: () async {
                            _down = null;
                            _move = null;
                            _up = null;
                            if (mounted) setState(() {});
                          },
                          icon: Icon(Icons.remove_circle)),
                    ),
                  ],
                ))));
        _down = null;
        _move = null;
        _up = null;
      }

      return _stackMain!;
    }

    return _buildImg();
  }

  Offset? _down;
  Offset? _move;
  Offset? _up;

  Widget _buildImg() {
    var temp = _source.toLowerCase().trim();
    Widget img;
    if (temp.startsWith("@")) {
      img = Image.asset(_source.substring(1), height: _h, width: _w);
    } else if (temp.startsWith("http:")) {
      img = Image.network(_source, height: _h, width: _w);
    } else if (temp.startsWith("https:")) {
      img = Image.network(_source, height: _h, width: _w);
    } else {
      img = Image.file(File(_source), height: _h, width: _w);
    }
    var listener = Listener(
      onPointerDown: (PointerDownEvent e) async {
        _down = e.localPosition;
        // print("down");
        // print(e.localPosition);
      },
      onPointerMove: (PointerMoveEvent e) async {
        _move = e.localPosition;
      },
      onPointerUp: (PointerUpEvent e) async {
        _up = e.localPosition;
        // print("up");
        // print(e.localPosition);
        if (mounted) setState(() {});
      },
      child: img,
    );
    return listener;
  }
}
