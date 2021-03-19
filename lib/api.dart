import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'db.dart';
import 'tts.dart';

import 'key.dart' as key;

/*
- We get the definition by a HTTP request, and then we process that request to a listview which all the short defs are displayed, 
categorized into noun, verb, and adjective
- uses a future since we are running a http request that might take a bit of time to respond, so we wait for it
 */

Future<WordDefinition> getDef(String word) async {
  final http.Response response = await http.get(
    'https://dictionaryapi.com/api/v3/references/collegiate/json/$word?key=${key.dictApiKey}',
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  print(response.statusCode);

  if (response.statusCode == 200) {
    // print(json.decode(response.body));
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

  static Widget buildDef(List<dynamic> json, String word) {
    Map<String,List<String>> defs = {"noun":[], "verb":[], "adjective":[]};
    // check if there is no def:
    if (json.isEmpty || json[0] is String) { // the json could contain a list of strings that are similar to the entered word
      return Container(
        alignment: Alignment.center,
        child: Text(
          "No Definition found :c (is the word spelled right?)",
          style: TextStyle(fontSize: 16),
        )
      );
    }

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
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      itemCount: defs.length,
      itemBuilder: (BuildContext context, int index) {
        List<Container> listDef = [];
        // print(defs[index]);
        if (defs.values.elementAt(index) != null && defs.values.elementAt(index).isNotEmpty) {
          listDef.add( // for title (e.g. noun, verb)
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 5, bottom: 5),
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

class UpdateLastWords extends InheritedWidget {
  List<String> lastWordList = [];

  UpdateLastWords({
    Key key,
    @required Widget child,
  }): super(key: key, child: child);

  static UpdateLastWords of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UpdateLastWords>();
  }

  @override
  bool updateShouldNotify(UpdateLastWords old) { 
    print("updating!");
    return !ListEquality().equals(lastWordList, old.lastWordList); // updates the related widgets when this is true
                                                                   // note: will cause the consumer to rebuild when the inherited widget itself changes state.
  }
}

class Search extends StatefulWidget {
  final String word;
  Search({Key key, this.word}) : super(key: key); // inherits the key from super class, key is used to identify widgets

  @override
  _SearchState createState() {
    return _SearchState();
  }
}

class _SearchState extends State<Search> {
  bool _saved;

  @override
  void initState() {
    // in here we also want to add the word to db
    // do it here so we know its a legit word
    WordDBProvider.db.newLastWord(widget.word);
    WordDBProvider.db.newFreqWord(widget.word);
    // print("init");
    _saved = false;
    super.initState();
    _checkSaved();
    // UpdateLastWords.of(context).id++;
  }

  void _checkSaved() async {
    _saved = await WordDBProvider.db.isWordSaved(widget.word);
    // print(_saved);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Future<WordDefinition> _futureDef = getDef(widget.word);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.word[0].toUpperCase()}${widget.word.substring(1)}"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            print(UpdateLastWords.of(context).lastWordList);
            UpdateLastWords.of(context).lastWordList = await WordDBProvider.db.getLastWords(); // hmm...
            print(UpdateLastWords.of(context).lastWordList);
            Navigator.of(context).pop();
          },
        ), 
      ),
      body: Column(
        // alignment: Alignment.center,
        // padding: const EdgeInsets.all(8.0),
        children: [
          Row(
            // alignment: Alignment.centerRight,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TTS(widget.word),
              IconButton(
                iconSize: 30.0,
                // padding: EdgeInsets.only(left:4,right:4),
                icon: _saved == true ? Icon(Icons.bookmark) : Icon(Icons.bookmark_border),
                onPressed: () {
                  setState(() {
                    _saved = !_saved;
                  });
                  if (_saved == true) {
                    WordDBProvider.db.newSavedWord(widget.word);
                  }
                  else {
                    WordDBProvider.db.removeSavedWord(widget.word);
                  }
                }
              )
          ]),
          Expanded(
            // alignment: Alignment.center,
            // padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              // transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              padding: const EdgeInsets.only(left: 10, right : 10, bottom: 15),
              child: FutureBuilder<WordDefinition>(
              future: _futureDef,
              builder: (context, snapshot) {
                // print(snapshot);
                if (snapshot.hasData) {
                  return WordDefinition.buildDef(snapshot.data.json, widget.word);
                  // Text(snapshot.data.def);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return CircularProgressIndicator();
                }
              },
            ))
          )
        ]
      ),
    );
  }
}
