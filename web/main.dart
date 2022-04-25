import 'dart:html';
import 'dart:async';

void main() {
  var g = Game();
  g.runGame();
  g.runDisplay();
}

class Game {
  late CanvasElement canvas;
  late CanvasRenderingContext2D cxt;
  num lastFrame = 0.0;
  final num updateTime = 50.0;  /* 20 FPS */
  Round? round;

  Game() {
    canvas = querySelector('#canvas') as CanvasElement;
    cxt = canvas.getContext('2d') as CanvasRenderingContext2D;
  }

  Future runDisplay() async {
    updateDisplay(await window.animationFrame);
  }

  void updateDisplay( num delta ) async {
    // Check whether it's time for an update.
    if(delta - lastFrame > updateTime) {
      if(round != null) {  /* Should always be true */
        round!.render(cxt);
      }

      lastFrame = delta;
    }

    // Update on the next tick.
    updateDisplay(await window.animationFrame);
  }

  void runGame() async {
    window.onKeyDown.listen(
      (KeyboardEvent ev) { round?.handleKeypress(ev); } );

    while(true) {  // Loop forever
      round = Round();
      await round!.play();
    }
  }
}

class Round {
  String phrase = "Hello, world!";
  List<bool> guesses = List.filled(26, false);
  StreamController<int> onSelectLetter = StreamController<int>();
  int state = 0;
      /* 0 = in progress
       * 1 = winner
       * 2 = loser */
  int misses = 0;
  final int maxMisses = 6;

  Round();

  Future<void> play() async {
    // Pick a word -- already done.

    await for(var letter in onSelectLetter.stream) {
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
    // Draw a base background
    cxt.fillStyle = "pink";
    cxt.fillRect(0, 0, cxt.canvas.width!, cxt.canvas.height!);

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
    cxt.fillText(String.fromCharCodes(letters), 50, 50);

    // Display number of misses
    cxt.fillText("Misses: ${misses}", 50, 600);

    if(state > 0) {
      cxt.fillStyle = 'rgba(0, 0, 0, 0.8)';
      cxt.fillRect(0, 0, cxt.canvas.width!, cxt.canvas.height!);
      cxt.fillStyle = "white";
      cxt.fillText(state == 1 ? "Winner" : "Loser", 200, 300);
    }
  }
}
