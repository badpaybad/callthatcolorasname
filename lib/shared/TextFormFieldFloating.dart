import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter/widgets.dart';
import '/AppContext.dart';

class TextFormFiledFloatingUi extends StatefulWidget {
  var TextController = TextEditingController();

  final TextFormState = GlobalKey<FormState>();

  var focusNode = FocusNode();

  TextFormFiledFloatingUi({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TextFormFiledFloatingUiState();
  }
}

class _TextFormFiledFloatingUiState extends State<TextFormFiledFloatingUi> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: widget.focusNode,
      key: widget.TextFormState,
      controller: widget.TextController,
    );
  }
}
