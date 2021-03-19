import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'dart:async';
// import 'package:flutter/widgets.dart';

/*
- We need 2 tables to store some value
 */

class LastWord {
  final int id;
  final String word;

  LastWord({this.id, this.word});

  Map<String, dynamic> toMap() => {
    "id": id,
    "word": word,
  };
}

class FreqWord {
  final int id;
  final String word;
  final int freq;

  FreqWord({this.id, this.word, this.freq});

  Map<String, dynamic> toMap() => {
    "id": id,
    "word": word,
    "freq": freq,
  };
}

class WordDBProvider {
  WordDBProvider._();
  static final WordDBProvider db = WordDBProvider._();

  static Database _database;

  Future<Database> get database async {
    // resetting the db
    // Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // String path = join(documentsDirectory.path, "last_word.db");
    // await deleteDatabase(path);

    if (_database != null) {
      return _database;
    }

    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "last_word.db");
    return await openDatabase(path, version: 1, onOpen: (db) {
    }, onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE LastWord ("
          "id INTEGER PRIMARY KEY,"
          "word TEXT"
          ")");
      await db.execute("CREATE TABLE FreqWord ("
          "id INTEGER PRIMARY KEY,"
          "word TEXT,"
          "freq INTEGER"
          ")");
      await db.execute("CREATE TABLE SavedWord ("
          "id INTEGER PRIMARY KEY,"
          "word TEXT"
          ")");
    });
  }

  newLastWord(String word) async {
    final db = await database;
    var res = await db.insert("LastWord", {"word": word}, conflictAlgorithm: ConflictAlgorithm.ignore);
    return res;
  }

  newFreqWord(String word) async { // update if already exists, otherwise insert new word
    final db = await database;
    // e.g. wordFound = [{"id" : 1, "freq" : 2}, ...]
    List<Map> wordFound = await db.query("FreqWord", where: "word = ?", whereArgs: [word], columns: ["id", "freq"], distinct: true);
    // print("wordFound");
    // print(wordFound);
    var res;
    if (wordFound.length != 0) {
      // print(wordFound);
      res = await db.update("FreqWord", {"freq" : wordFound[0]["freq"] + 1} ,where: "id = ?", whereArgs: [wordFound[0]["id"]]); // should only be 1 word, or null
    }
    else {
      res = await db.insert("FreqWord", {"word": word, "freq" : 1});
    }
    return res;
  }

  // returns list of words
  Future<List<String>> getLastWords() async {
    // retrive all last 50 entered words
    final db = await database;
    var wordFound = await db.query("LastWord", columns: ["word"], distinct: true, orderBy: "id DESC", limit: 50);
    // print(wordFound);
    if (wordFound == null) {
      return null;
    }
    else {
      List<String> ls = [];
      wordFound.forEach((element) {
        ls.add(element["word"]);
      });
      return ls;
    }
  }

  Future<List<Map<String, String>>> getFreqWords() async {
    // a list of the top 50 words searched
    final db = await database;
    var wordFound = await db.query("FreqWord", columns: ["word", "freq"], distinct: true, orderBy: "freq DESC", limit: 50);
    // print(wordFound);
    if (wordFound.length == 0) {
      return null;
    }
    else {
      List<Map<String, String>> ls = [];
      wordFound.forEach((element) {
        var tmp = new Map<String, String>();
        tmp[element["word"]] = element["freq"].toString();
        ls.add(tmp);
      });
      print(ls);
      return ls;
    }
  }

  newSavedWord(String word) async {
    final db = await database;
    // var res = await db.rawInsert("INSERT INTO SavedWord (word) VALUES (?)", [word]);
    var res = await db.insert("SavedWord", {"word": word}, conflictAlgorithm: ConflictAlgorithm.ignore);
    return res;
  }

  removeSavedWord(String word) async {
    final db = await database;
    // var res = await db.rawDelete("DELETE FROM SavedWord WHERE word = ?", [word]);
    var res = await db.delete("SavedWord", where: 'word = ?', whereArgs: [word]);
    return res;
  }

    Future<List<String>> getSavedWords(bool orderByAlpha) async {
    // retrive all saved words
    final db = await database;
    var wordFound;
    // print(orderByAlpha);
    if (!orderByAlpha) {
      wordFound = await db.query("SavedWord", columns: ["word"], distinct: true, orderBy: "id DESC");
    }
    else {
      wordFound = await db.query("SavedWord", columns: ["word"], distinct: true, orderBy: "word");
    }
    // print(wordFound);

    if (wordFound.length == 0) {
      return null;
    }
    else {
      List<String> ls = [];
      wordFound.forEach((element) {
        ls.add(element["word"]);
      });
      return ls;
    }
  }

  Future<bool> isWordSaved(String word) async {
    final db = await database;
    var wordFound = await db.query("SavedWord", columns: ["word"], distinct: true, where: "word = ?", whereArgs: [word]);
    if (wordFound.length == 0)
      return false;
    else
      return true;
  }
}