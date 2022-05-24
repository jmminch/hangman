/* input.dart */

import 'dart:html';
import 'dart:async';

class InputEvent {
  int type = 0;  /* 0 = keyboard, 1 = button click */
  int value = 0; /* char code for keystroke, button ID for button. */

  InputEvent(this.type, this.value);
}

class InputHandler {

  final events = 
    StreamController<InputEvent>.broadcast();

  List<Button> buttons = [];

  InputHandler() {
    window.onKeyDown.listen((ev) { events.add(InputEvent(0, ev.keyCode)); });
    var canvas = querySelector('#canvas') as CanvasElement;
    canvas.onClick.listen((ev) {
      for(var b in buttons) {
        if(b.checkClick(ev.offset.x, ev.offset.y)) {
          events.add(InputEvent(1, b.id));
        }
      }
    });
  }
}

class Button {

  int id;
  num x;
  num y;
  num w;
  num h;

  Button( this.id, this.x, this.y, this.w, this.h );

  bool checkClick( num mx, num my ) {
    return (mx >= x && mx < x + w && my >= y && my < y + h);
  }
}
