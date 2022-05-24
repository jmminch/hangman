/* image.dart */

import 'dart:html';
import 'dart:async';

class ImageManager {
  
  Map<String, ImageElement> cache = {};

  Completer loaded = Completer();
  int count = 0;

  ImageManager() {
    preloadImages();
  }

  Future<void> preloadImages() async {
    preload("hangman-0");
    preload("hangman-1");
    preload("hangman-2");
    preload("hangman-3");
    preload("hangman-4");
    preload("hangman-5");
    preload("hangman-6");
  }

  void preload( String id ) {
    count++;
    cache[id] = ImageElement(src: "images/$id.png");
    cache[id]?.onLoad.first.then((e) {
      count--;
      if(count < 1) {
        loaded.complete();
      }
    });
  }
}
