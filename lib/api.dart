import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

/*
- We get the definition by a HTTP request, and then we process that request to a listview which all the short defs are displayed, 
categorized into noun, verb, and adjective
- uses a future since we are running a http request that might take a bit of time to respond, so we wait for it
 */

Future<WordDefinition> getDef(String word) async {
  final http.Response response = await http.get(
    'https://dictionaryapi.com/api/v3/references/collegiate/json/$word?key=69d47b46-068c-48a7-adb9-6b0bcb49f649',
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  print(response.statusCode);

  if (response.statusCode == 200) {
    print(json.decode(response.body));
    // return WordDefinition.fromJson(json.decode(response.body));
    return WordDefinition(json: json.decode(response.body));
  } else {
    throw Exception('Failed to get word definition.');
  }
}

class WordDefinition {
  // final String word;
  // final List<String> def;
  final List<dynamic> json;

  WordDefinition({this.json});

  // factory WordDefinition.fromJson(List<Map<String, dynamic>> json) {
  //   // return WordDefinition(word: json['meta']['id'], def: json['shortdef'][0]);
  //   return WordDefinition(json: json);
  // }

  static Widget buildDef(List<dynamic> json) {
    Map<String,List<String>> defs = {"noun":[], "verb":[], "adjective":[]};
    json.forEach((element) {
      if (element["fl"].toString().toLowerCase().contains("noun")) {
        element['shortdef'].forEach((s) {
          defs["noun"].add(s);
        });
      }
      else if (element["fl"].toString().toLowerCase().contains("verb")) {
        element['shortdef'].forEach((s) {
          defs["verb"].add(s);
        });
      }
      else if (element["fl"].toString().toLowerCase().contains("adjective")) {
        element['shortdef'].forEach((s) {
          defs["adjective"].add(s);
        });
      }
      else {
        // do nothing
      }
    });
    // print(defs);

    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(8),
      itemCount: defs.length,
      itemBuilder: (BuildContext context, int index) {
        List<Container> listDef = new List<Container>();
        // print(defs[index]);
        if (defs.values.elementAt(index) != null && defs.values.elementAt(index).isNotEmpty) {
          listDef.add( // for title (e.g. noun, verb)
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 10, bottom: 5),
              child: Text(
                defs.keys.elementAt(index), 
                style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 24
                ), 
                textAlign: TextAlign.left,)
              )
            );

          int count = 1;
          defs.values.elementAt(index).forEach((element) { 
            listDef.add(
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "$count.  " + element,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    // letterSpacing: 0.3,
                    wordSpacing: 0.3
                )
              )
            ));
            count++;
          });
        } else {
          return Container(width: 0.0, height: 0.0);
        }
        // print("YOOOOOO" + listDef[0]);
        return Column(children: listDef);
      }
    );
  }
}

class Search extends StatefulWidget {
  final String word;
  Search({Key key, this.word}) : super(key: key);

  @override
  _SearchState createState() {
    return _SearchState();
  }
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    Future<WordDefinition> _futureDef = getDef(widget.word);
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.word[0].toUpperCase()}${widget.word.substring(1)}"),
      ),
      body: Container(
          // alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Container(
            // alignment: Alignment.center,
            child: 
              FutureBuilder<WordDefinition>(
                future: _futureDef,
                builder: (context, snapshot) {
                  // print(snapshot);
                  if (snapshot.hasData) {
                    return WordDefinition.buildDef(snapshot.data.json);
                    // Text(snapshot.data.def);
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              )
          )),
    );
  }
}
