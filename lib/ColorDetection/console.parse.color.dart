import 'dart:async';
import 'dart:io';

import '/shared/ColorHelper.dart';

Future<void> main() async {
  var contents = await File('color.html').readAsString();

  var listTr = splitByTag("tr", contents);

  Map<String, int> idxMainColors = {};

  for (var i = 0; i < listTr.length; i++) {
    var tr = listTr[i];
    if (tr.indexOf("<h2") > 0) {
      idxMainColors[tr] = i;
    }
  }

  var keys = idxMainColors.keys.toList();
  var values = idxMainColors.values.toList();

  print(values);
  Map<String, List<String>> mapTrTd = {};

  for (var i = 0; i < keys.length - 1; i++) {
    var k = keys[i];
    var v = values[i];
    var vn = values[i + 1];
    mapTrTd[k] = [];

    for (var j = v + 1; j < vn; j++) {
      mapTrTd[k]!.add(listTr[j]);
    }
  }

  Map<String, List<List<String>>> contentsGroup = {};
  final beforeCapitalLetter = RegExp(r"(?=[A-Z])");

  for (String g in mapTrTd.keys) {
    var listTd = mapTrTd[g]!;

    var mainColor = getContentTag("h2", g).replaceAll("Colors", "").trim();
    contentsGroup[mainColor] = [];

    for (var td in listTd) {
      var dataTds = splitByTag("td", td);
      List<String> foundData = [];
      if (dataTds.isNotEmpty) {
        for (var ttd in dataTds) {
          var vala=getContentTag("a", ttd);
          foundData.add(vala.trim().replaceAll("#", ""));
        }
        foundData[0]= foundData[0].split(beforeCapitalLetter).join(" ");
        contentsGroup[mainColor]!.add(foundData);
      }
    }
  }

  var namesInCode=[];
  for(var k in contentsGroup.keys){
    var names = contentsGroup[k]!;
    for(var n in names){
      namesInCode.add('["${n[1]}","${n[0]}","$k"]');
    }
  }

  var linecodes= namesInCode.join(",");

  print(linecodes);

  Map<String,List<dynamic>> groupColor={};
  for(var itm in ColorHelper.instance.names){
    print(itm);
    var k=itm[2];
    if(groupColor[k]==null){
      groupColor[k]=[];
    }
    groupColor[k]!.add(itm);
  }

  var html="";
  for(var k in groupColor.keys){
    var lines= groupColor[k]!;
    html=html+"<div>$k</div><table>";
    for(var l in lines){
      html=html+"<tr><td style='background-color:#${l[0]}' >${l[0]}</td><td>${l[1]}</td><td>${l[2]}</td></tr>";
    }
    html=html+"</table>";
  }
  var file=File("colornames.html");
  await file.writeAsString(html);

}

String getContentTag(String tag, String src) {
  var tempsrc = src;
  var btag = "<$tag";
  var etag = "</$tag>";

  var idx = tempsrc.indexOf(btag);
  if(idx<0) return "";
  tempsrc = tempsrc.substring(idx + btag.length);
  idx = tempsrc.indexOf(">");
  tempsrc = tempsrc.substring(idx + 1);
  idx = tempsrc.indexOf(etag);
  tempsrc = tempsrc.substring(0, idx);
  return tempsrc;
}

List<String> splitByTag(String tag, String src) {
  List<String> temp = [];
  var btag = "<$tag";
  var etag = "</$tag>";

  var tempSrc = src;

  while (tempSrc.contains(etag)) {
    var idx = tempSrc.indexOf(btag);
    var idx1 = tempSrc.indexOf(etag);
    if (idx1 <= 0) break;
    idx1 = idx1 + etag.length;
    if (idx1 > tempSrc.length) idx1 = tempSrc.length;

    var tagWithConent = tempSrc.substring(idx, idx1);
    temp.add(tagWithConent);
    tempSrc = tempSrc.substring(idx1);
  }

  return temp;
}
