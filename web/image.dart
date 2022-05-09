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
    preload("round_bg");
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
