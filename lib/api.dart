import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

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
    return WordDefinition.fromJson(json.decode(response.body)[0]);
  } else {
    throw Exception('Failed to get word definition.');
  }
}

class WordDefinition {
  final String word;
  final String def;

  WordDefinition({this.word, this.def});

  factory WordDefinition.fromJson(Map<String, dynamic> json) {
    return WordDefinition(word: json['meta']['id'], def: json['shortdef'][0]);
    // return WordDefinition(
    //     word: json['meta']['id'], def: json['def']['sseq']['dt'][1]);
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
        title: Text('Def...'),
      ),
      body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Text(''),
              // RaisedButton(
              //   child: Text('Go back'),
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              // ),
              FutureBuilder<WordDefinition>(
                future: _futureDef,
                builder: (context, snapshot) {
                  print(snapshot);
                  if (snapshot.hasData) {
                    return Text(snapshot.data.def);
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  } else {
                    return CircularProgressIndicator();
                  }

                  // return CircularProgressIndicator();
                },
              )
            ],
          )),
    );
  }
}
