import 'dart:async';

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'api.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'db.dart';

// to do:
/*
- voice recognition
- styling
- done!
- text to speech?
*/

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return UpdateLastWords(child: MaterialApp(
      title: 'Simple Dictionary',
      theme: ThemeData(primaryColor: Colors.blue[200]),
      home: MainPage(),
    ));
  }
}

// class UpdateLastWords extends InheritedWidget {
//   int id = 0;

//   UpdateLastWords({
//     Key key,
//     @required Widget child,
//   }): super(key: key, child: child);

//   static UpdateLastWords of(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType<UpdateLastWords>();
//   }

//   @override
//   bool updateShouldNotify(UpdateLastWords old) => id != old.id;
// }

// make this stateful and add id, and when we change id we redraw the list - or use inherited widget
class MainPage extends StatelessWidget {
  
  // StreamController<List<String>> _refreshController;

  Future<List<String>> _buildLastWords() async { // for the main page
    print("getting last words");
    return await WordDBProvider.db.getLastWords();
  }

  // static Stream<List<String>> _refreshList = (() async* { // we can use this function to call the refresh of the list
  //   await Future<void>.delayed(Duration(seconds: 1));
  //   // yield 1;
  //   yield ["1"];
  //   await Future<void>.delayed(Duration(seconds: 1));

  //   // var x = _buildLastWords();
  // })();

  @override
  Widget build(BuildContext context) {
    var lastWords = UpdateLastWords.of(context).lastWordList;
    return GestureDetector(
      onTap: () {
        // FocusScopeNode currentFocus = FocusScope.of(context);
        // if (!currentFocus.hasPrimaryFocus) {
        //   currentFocus.unfocus();
        // }
        FocusScope.of(context)
            .requestFocus(new FocusNode()); // not the best way
      },
      child: Scaffold(
        drawer: SideBar(), // side bar widget
        appBar: AppBar(
          title: Text('Simple Dictionary'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.mic),
            ),
          ],
        ),
        body: new Container(
            // color: Colors.blue[100],
            decoration: BoxDecoration( border: Border(bottom: BorderSide(width: 0.5)) ),
            padding: const EdgeInsets.all(10),
            child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: SearchBar(), // search bar widget
                  ),
                  SizedBox(height: 20),
                  Expanded(
                      child: lastWords.length != 0 ? lastWordsBuild(lastWords) : FutureBuilder<List<String>>(
                        future: _buildLastWords(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return lastWordsBuild(snapshot.data);
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}");
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                      )
                  )
                ])))
    );
  }

  ListView lastWordsBuild(List<String> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return Column(
          children: <Widget>[
            ListTile(
              title: FlatButton(
                height: 50,
                child: Row(
                  children: [Text(
                    data[index],
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.right,
                  )]
                ),
                onPressed: () => _searchWord(context, data[index]),
              ),
            ),
            Divider(),
          ],
        );
      },
    );
  }

  // this should go to the search page
  static void _searchWord(BuildContext context, String word) async {
    // print("word");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Search(word: word)), // here is where the search happens
    );
  }
  
}

void _searchWord(BuildContext context, String word) async {
  // print("word");
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => Search(word: word)), // here is where the search happens
  );
}

class SearchBar extends StatefulWidget {
  @override
  _SearchBarState createState() => _SearchBarState();
}

// for the search bar & auto suggest
class _SearchBarState extends State<SearchBar> {
  final _searchController = TextEditingController();
  String inputText;

  @override
  void initState() {
    inputText = "";
    _searchController.addListener(() { // this way we will be able to make the clear button appear
      setState(() {
        inputText = _searchController.text;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          hintText: 'Search',
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.blue,
          ),
          suffixIcon: hidingIcon(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 40.0),
        ),
        controller: _searchController,
        onSubmitted: (value) {
          // check for text***
          if (value.isEmpty || value.length > 20 || _checkCharOfWord(value)) {
            _showTextInvalid();
          } else {
            // _searchController.text = "";
            setState(() {
              _searchController.clear();
            });
            MainPage._searchWord(context, value.toLowerCase());
          }
        },
      ),
      // controller: _searchController,
      itemBuilder: (context, item) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              item,
              // style: TextStyle(fontSize: 16.0),
            ),
            Padding(
              padding: EdgeInsets.all(15.0),
            )
          ],
        );
      },
      onSuggestionSelected: (suggestion) {
        setState(() {
          _searchController.text = suggestion;
        });
        if (suggestion.isEmpty || suggestion.length > 20 || _checkCharOfWord(suggestion)) {
          _showTextInvalid();
        } else {
          setState(() {
            _searchController.clear();
          });
          MainPage._searchWord(context, suggestion);
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => Search(word: suggestion)),
          // );
        }
      },
      suggestionsCallback: (pattern) {
        return _suggestString(pattern);
      },
    );
  }

  bool _checkCharOfWord(String word) {
    return (word.replaceAll(new RegExp("[a-zA-Z]+"), "") != ""); // if there are illegal characters, the string is not empty
  }

  List<String> _suggestString(String pattern) {
    if (pattern.isEmpty) {
      return null;
    }
    List<String> temp = new List<String>();
    nouns.forEach((element) {
      if (element.startsWith(pattern)) {
        temp.add(element);
      }
    });
    return temp;
  }

  Widget hidingIcon() {
    if (inputText.isNotEmpty) {
      // print("ASD");
      return IconButton(
          icon: Icon(
            Icons.clear,
          ),
          splashColor: Colors.black,
          onPressed: () {
            setState(() {
              _searchController.clear();
              // _searchController.text = "";
              inputText = "";
            });
          });
    } else {
      return null;
    }
  }

  Future<void> _showTextInvalid() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Search Terms'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('The textfield cannot be empty or exceed 20 characters.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class SideBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        // Important: Remove any padding from the ListView.
        // padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image(image: AssetImage('images/doge.jpg'))]
            )
          ),
          Expanded(
              child: ListView(children: <Widget>[
            ListTile(
              title: Text('Most Frequent Words'),
              leading: Icon(Icons.book_rounded),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => buildMostFreq(context)),
                );
              },
            ),
            ListTile(
              title: Text('Saved Words'),  
              leading: Icon(Icons.bookmark), 
              onTap: () {
                // Navigator.pop(context); // add a sort by newest or alphabetical
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SavedWordsTab()),
                );
              },
            ),
          ])),
          Container(
              padding: EdgeInsets.all(10),
              height: 50,
              child: Row(children: <Widget>[
                Image(
                    image: AssetImage('images/MWLogo_LightBG_120x120_2x.png')),
                VerticalDivider(),
                Text(
                  "Powered by Merriam-Webster, Inc.",
                  style: TextStyle(fontSize: 12),
                )
              ])),
        ],
      ),
    );
  }

  Future<List<Map<String, String>>> _buildFreqWords() async { // for the main page
    return await WordDBProvider.db.getFreqWords();
  }

  Widget buildMostFreq(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Frequently Searched Words")
      ),
      body: Container(
      // color: Colors.blue[100],
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 0.5))),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: _buildFreqWords(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                      print(snapshot.data);
                      return ListView.builder(
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: <Widget>[
                              ListTile(
                                title: FlatButton(
                                  height: 50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        snapshot.data[index].keys.first,
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.right,
                                      ),
                                      Text(
                                        snapshot.data[index].values.first,
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.right,
                                      )
                                    ]
                                  ),
                                  onPressed: () => MainPage._searchWord(context, snapshot.data[index].keys.first),
                                ),
                              ),
                              Divider(),
                            ],
                          );
                        },
                      );
                  } else if (snapshot.hasError) {
                    // print(snapshot.data);
                    return Text("${snapshot.error}");
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              )
          )
        ]))
    );
  }
}


// here we are using stateful builder to update the local state
class SavedWordsTab extends StatelessWidget {
  List<bool> isSelected = [true, false];

  Future<List<String>> _buildSavedWords(bool orderByAlpha) async { // for the main page
    return await WordDBProvider.db.getSavedWords(orderByAlpha);
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, StateSetter setState) =>
      Scaffold(
        appBar: AppBar(
          title: Text("Your Saved Words")
        ),
        body: Container(
          // color: Colors.blue[100],
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 0.5))),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  // color: Colors.black
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  return ToggleButtons(
                    constraints: BoxConstraints.expand(width: constraints.maxWidth / 2 - 1.5, height: 25), //number 2 is number of toggle buttons, -1.5 for border
                    borderRadius: BorderRadius.circular(5),
                    textStyle: TextStyle(fontSize: 16),
                    children: <Widget>[ // buttons
                      Text("Newest"),
                      Text("Alphabetical"),
                    ],
                    onPressed: (int index) {
                      setState(() {
                        for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
                          if (buttonIndex == index) {
                            isSelected[buttonIndex] = true;
                          } else {
                            isSelected[buttonIndex] = false;
                          }
                        }
                      });
                    },
                    isSelected: isSelected,
                  );
                })
              ),
              Expanded(
                  child: FutureBuilder<List<String>>(
                    future: _buildSavedWords(isSelected[1]), // true if we want to sort by alpha
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                          print(snapshot.data);
                          return ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: <Widget>[
                                  ListTile(
                                    title: FlatButton(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            snapshot.data[index],
                                            style: TextStyle(fontSize: 16),
                                            textAlign: TextAlign.right,
                                          ),
                                        ]
                                      ),
                                      onPressed: () => MainPage._searchWord(context, snapshot.data[index]),
                                    ),
                                  ),
                                  Divider(),
                                ],
                              );
                            },
                          );
                      } else if (snapshot.hasError) {
                        // print(snapshot.data);
                        return Text("${snapshot.error}");
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  )
              )
            ]
          )
        )
      )
    );
  }
}
