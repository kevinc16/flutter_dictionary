import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'api.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

// to do:
/*
- formatting of definitions (at least a little better)
- most recent words thru sqlite
- sidebar stuff
*/

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primaryColor: Colors.blue[200]),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  final _suggestions = <WordPair>[];
  Widget _buildRow(WordPair pair) {
    return ListTile(
      title: Text(
        pair.asPascalCase,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            drawer: SideBar(),
            appBar: AppBar(
              title: Text('Dictionary'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.mic),
                ),
              ],
            ),
            body: new Container(
                // color: Colors.blue[100],
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(width: 0.5))),
                padding: const EdgeInsets.all(10),
                child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: SearchBar(),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                          child: Container(
                              height: 50,
                              child: ListView.builder(
                                  padding: EdgeInsets.all(16.0),
                                  itemBuilder: /*1*/ (context, i) {
                                    // here we display the most recent searched words?
                                    return null;
                                  })))
                    ]))));
  }
}

class SearchBar extends StatefulWidget {
  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _searchController = TextEditingController();
  var inputText = "";

  @override
  void initState() {
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
          // focusedBorder: InputBorder.none,
          // enabledBorder: InputBorder.none,
          // errorBorder: InputBorder.none,
          // disabledBorder: InputBorder.none,
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
          if (value.isEmpty || value.length > 20) {
            _showTextInvalid();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Search(word: value)),
            );
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
        if (suggestion.isEmpty || suggestion.length > 20) {
          _showTextInvalid();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Search(word: suggestion)),
          );
        }
      },
      suggestionsCallback: (pattern) {
        return _suggestString(pattern);
      },
    );
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
    if (_searchController.text.length > 0) {
      return IconButton(
          icon: Icon(
            Icons.clear,
          ),
          splashColor: Colors.black,
          onPressed: () {
            setState(() {
              _searchController.clear();
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
            padding: EdgeInsets.zero,
            // child: Text('What to do...'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          Expanded(
              child: ListView(children: <Widget>[
            ListTile(
              title: Text('Most Frequent'),
              leading: Icon(Icons.book),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Setting'),
              leading: Icon(Icons.settings),
              onTap: () {
                Navigator.pop(context);
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
}
