import 'dart:html';
import 'dart:async';
import 'dart:math';

import 'input.dart';
import 'image.dart';

Game game = Game();

void main() async {
  await game.images.loaded.future;
  game.runGame();
  game.runDisplay();
}

class Game {
  int state = 0;
      /*  0 == title screen
       *  1 == level select
       *  2 == round */
  late Round round;

  late CanvasElement canvas;
  late CanvasRenderingContext2D cxt;
  Random random = Random();

  InputHandler input = InputHandler();
  ImageManager images = ImageManager();

  List<String> phrases = [
    "Hello, world!",
    "Emerson likes neon stuff.",
    "Cuphead" ];

  Game() {
    canvas = querySelector('#canvas') as CanvasElement;
    cxt = canvas.getContext('2d') as CanvasRenderingContext2D;
  }

  Future runDisplay() async {
    updateDisplay(await window.animationFrame);
  }

  void updateDisplay( num delta ) async {
    switch(state) {
      case 2:  /* round */
        round.render(cxt);
        break;
    }

    /* Outline buttons for debugging. */
    /*
    for(var b in input.buttons) {
      cxt.strokeStyle = 'green';
      cxt.strokeRect(b.x, b.y, b.w, b.h);
    }
    */

    // Update on the next tick.
    updateDisplay(await window.animationFrame);
  }

  void runGame() async {
    while(true) {  // Loop forever
      round = Round(phrases[random.nextInt(phrases.length)]);
      state = 2;
      await round.play();
    }
  }
}

class Round {
  String phrase;
  List<bool> guesses = List.filled(26, false);
  StreamController<int> onSelectLetter = StreamController<int>();
  int state = 0;
      /* 0 = in progress
       * 1 = winner
       * 2 = loser */
  int misses = 0;
  final int maxMisses = 6;
  bool dirty = true;

  Round( this.phrase );

  Future<void> play() async {
    dirty = true;

    /* Set up buttons. */
    for(var i = 0; i < 26; i++) {
      var b = Button(i, 800 + (i % 7) * 40, 265 + (i ~/ 7) * 40, 30, 35);
      game.input.buttons.add(b);
    }

    await for(var event in game.input.events.stream) {
      dirty = true;

      int letter = 0;
      if(event.type == 0) {
        letter = event.value - 65;
      } else {
        letter = event.value;
      }

      if(letter < 0 || letter > 25) continue;

      if(guesses[letter]) {
        // Picked a letter that had already been guessed.
        continue;
      }

      guesses[letter] = true;

      if(solved()) {
        state = 1;
        break;
      }

      if(!phraseContains(letter)) {
        misses++;
        if(misses >= maxMisses) {
          state = 2;
          break;
        }
      }
    }

    game.input.buttons.clear();

    // Game over; wait 5 seconds.
    await Future.delayed(Duration(seconds: 5));
  }

  void handleKeypress( KeyboardEvent ev ) {
    if(ev.keyCode < KeyCode.A || ev.keyCode > KeyCode.Z) {
      return;
    }

    onSelectLetter.add(ev.keyCode - KeyCode.A);
  }

  // Check whether the puzzle has been solved.
  bool solved() {
    for (var c in phrase.toUpperCase().codeUnits) {
      if(c < 65 || c > 90) continue;
      if(!guesses[c - 65]) return false;
    }
    return true;
  }

  // Check whether the puzzle contains the given letter.
  bool phraseContains( int letter ) {
    letter += 65;
    return phrase.toUpperCase().codeUnits.contains(letter);
  }

  void render( CanvasRenderingContext2D cxt ) {
    if(!dirty) return;

    // Draw a base background
    var dest = Rectangle(0, 0, cxt.canvas.width!, cxt.canvas.height!);
    cxt.drawImageToRect(game.images.cache["round_bg"]!, dest);

    // Create a phrase containing blanks for unguessed letters.
    var letters = List<int>.from(phrase.codeUnits);

    for( int i = 0; i < letters.length; i++ ) {
      var l = phrase.toUpperCase().codeUnitAt(i);
      if(l >= 65 && l <= 90) {
        if(!guesses[l - 65]) {
          letters[i] = 95;  // Underscore
        }
      }
    }

    // Display the phrase.
    cxt.fillStyle = "black";
    cxt.font = '48px mono';
    for(int i = 0; i < letters.length; i++) {
      cxt.fillText(String.fromCharCode(letters[i]), 50 + 40 * i, 50);
    }

    // Display used letters.
    for(int i = 0; i < 26; i++) {
      int x = 800 + (i % 7) * 40;
      int y = 300 + (i ~/ 7) * 40;

      cxt.fillStyle = "black";
      cxt.fillText(String.fromCharCode(i + 65), x, y);
      if(guesses[i]) {
        cxt.fillStyle = "red";
        cxt.fillText('x', x, y - 3);
      }
    }

    // Display number of misses
    cxt.fillStyle = "black";
    cxt.fillText("Misses: $misses", 50, 600);

    if(state > 0) {
      cxt.fillStyle = 'rgba(0, 0, 0, 0.8)';
      cxt.fillRect(0, 0, cxt.canvas.width!, cxt.canvas.height!);
      cxt.fillStyle = "white";
      cxt.fillText(state == 1 ? "Winner" : "Loser", 200, 300);
    }

    dirty = false;
  }
}
