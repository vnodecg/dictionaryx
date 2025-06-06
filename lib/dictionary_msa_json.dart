import 'dart:convert';
import 'dart:io';

import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/src/dict_abstract.dart';
import 'package:dictionaryx/src/dictassets.dart';
import 'package:retrieval/trie.dart';

/// Complete dictionary with meanings, synonyms and antonyms.
class DictionaryMSAJson extends DictionaryAbs {
  String _currentWord = '';
  Trie? _trie;
  Map<String, dynamic> _currentJson = {};

  String _resolveAsset(String word) {
    var asset = DictAssets.dictAssets
        .lastWhere((ast) => word.compareTo(ast) >= 0, orElse: () => '');

    if (asset.isEmpty) {
      throw 'No asset file found for word: $word';
    }
    return asset;
  }

  Map<String, dynamic> _getAssetBundleFor(String word) {
    if (word == _currentWord) {
      return _currentJson;
    }
    String asset = _resolveAsset(word);
    _currentJson = jsonDecode(File('./assets/$asset.json').readAsStringSync());
    _currentWord = word;
    return _currentJson;
  }

  Map<String, dynamic> _getAssetEntry(String word) {
    return _getAssetBundleFor(word)[word];
  }

  /// Does the dictionary list the word.
  bool hasEntry(String word) {
    return _getAssetBundleFor(word).containsKey(word);
  }

  // /// Returns the entry for the given word.
  DictEntry getEntry(String word) {
    final assetEntry = _getAssetEntry(word);

    List<DictEntryMeaning> explanations =
        assetEntry['M'].map<DictEntryMeaning>((meaning) {
      var pos = getPos(meaning[0]!);
      return DictEntryMeaning(pos, meaning[1], List<String>.from(meaning[2]),
          List<String>.from(meaning[3]));
    }).toList();

    return DictEntry(word, explanations, List<String>.from(assetEntry['S']),
        List<String>.from(assetEntry['A']));
  }

  // /// Returns the number of word-entries of the dictionary.
  int length() {
    var ret = 0;
    for (var asset in DictAssets.dictAssets) {
      ret += _getAssetBundleFor(asset).keys.length;
    }
    return ret;
  }

  /// Returns the list of all words in the dictionary.
  List<String> words() {
    var ret = <String>[];
    for (var asset in DictAssets.dictAssets) {
      ret.addAll(_getAssetBundleFor(asset).keys);
    }
    return ret;
  }

  Future<Trie> trie() async {
    if (_trie == null) {
      _trie = Trie();
      for (var asset in DictAssets.dictAssets) {
        var bundle = await _getAssetBundleFor(asset);
        for (var word in bundle.keys) {
          _trie!.insert(word);
        }
      }
    }
    return _trie!;
  }
}
