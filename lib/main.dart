import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Türkçe Wordle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Türkçe Wordle'), centerTitle: true),
      body: Center(
        child: ElevatedButton(
          child: const Text('Oyna', style: TextStyle(fontSize: 24)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordleGame()),
            );
          },
        ),
      ),
    );
  }
}

class WordleGame extends StatefulWidget {
  const WordleGame({super.key});
  @override
  State<WordleGame> createState() => _WordleGameState();
}

class _WordleGameState extends State<WordleGame> {
  static const int maxGuesses = 6;
  static const int wordLength = 5;

  List<String> wordList = [];
  String? answer;
  List<String> guesses = [];
  List<List<LetterFeedback>> feedbacks = [];
  String currentGuess = '';
  bool isLoading = true;
  bool gameOver = false;
  String message = '';
  Map<String, LetterFeedback> keyboardStatus = {};

  // Turkish Q keyboard rows (classic order)
  static const List<List<String>> turkishQKeyboardRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'Ğ', 'Ü'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ş', 'İ'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'Ö', 'Ç'],
  ];

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  Future<void> loadWords() async {
    final wordsRaw = await rootBundle.loadString('lib/words.txt');
    final words = wordsRaw
        .split('\n')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.length == wordLength)
        .toList();
    setState(() {
      wordList = words;
      answer = (words..shuffle()).first;
      isLoading = false;
      guesses.clear();
      feedbacks.clear();
      currentGuess = '';
      gameOver = false;
      message = '';
      keyboardStatus.clear();
    });
  }

  void onLetter(String letter) {
    if (gameOver || isLoading) return;
    if (currentGuess.length < wordLength) {
      setState(() {
        currentGuess += letter;
      });
    }
  }

  void onBackspace() {
    if (gameOver || isLoading) return;
    if (currentGuess.isNotEmpty) {
      setState(() {
        currentGuess = currentGuess.substring(0, currentGuess.length - 1);
      });
    }
  }

  void onEnter() {
    if (gameOver || isLoading) return;
    final guess = currentGuess;
    if (guess.length != wordLength) {
      setState(() {
        message = '5 harfli bir kelime girin!';
      });
      return;
    }
    // Turkish locale uppercasing for comparison
    final guessUpper = guess.toUpperCase();
    if (!wordList.contains(guessUpper)) {
      setState(() {
        message = 'Geçersiz kelime!';
      });
      return;
    }
    final fb = getFeedback(guessUpper, answer!);
    setState(() {
      guesses.add(guessUpper);
      feedbacks.add(fb);
      // Update keyboard status
      for (int i = 0; i < wordLength; i++) {
        final l = guessUpper[i];
        final prev = keyboardStatus[l];
        if (fb[i] == LetterFeedback.correct) {
          keyboardStatus[l] = LetterFeedback.correct;
        } else if (fb[i] == LetterFeedback.present) {
          if (prev != LetterFeedback.correct) {
            keyboardStatus[l] = LetterFeedback.present;
          }
        } else {
          if (prev != LetterFeedback.correct && prev != LetterFeedback.present) {
            keyboardStatus[l] = LetterFeedback.absent;
          }
        }
      }
      if (guessUpper == answer) {
        gameOver = true;
        message = 'Tebrikler! Doğru bildiniz!';
      } else if (guesses.length >= maxGuesses) {
        gameOver = true;
        message = 'Kaybettiniz! Cevap: $answer';
      } else {
        message = '';
      }
      currentGuess = '';
    });
  }

  List<LetterFeedback> getFeedback(String guess, String answer) {
    // Implements Wordle feedback logic, Turkish sensitive
    List<LetterFeedback> result = List.filled(wordLength, LetterFeedback.absent);
    List<bool> answerUsed = List.filled(wordLength, false);

    // First pass: correct positions
    for (int i = 0; i < wordLength; i++) {
      if (guess[i] == answer[i]) {
        result[i] = LetterFeedback.correct;
        answerUsed[i] = true;
      }
    }
    // Second pass: present but wrong position
    for (int i = 0; i < wordLength; i++) {
      if (result[i] == LetterFeedback.correct) continue;
      for (int j = 0; j < wordLength; j++) {
        if (!answerUsed[j] && guess[i] == answer[j]) {
          result[i] = LetterFeedback.present;
          answerUsed[j] = true;
          break;
        }
      }
    }
    return result;
  }

  Widget buildBoard() {
    List<Widget> rows = [];
    for (int i = 0; i < maxGuesses; i++) {
      if (i < guesses.length) {
        final guess = guesses[i];
        final fb = feedbacks[i];
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(wordLength, (j) {
            return Container(
              margin: const EdgeInsets.all(4),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fb[j] == LetterFeedback.correct
                    ? Colors.green
                    : fb[j] == LetterFeedback.present
                        ? Colors.amber
                        : Colors.grey[400],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                guess[j],
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            );
          }),
        ));
      } else if (i == guesses.length && !gameOver) {
        // Current guess row (editable)
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(wordLength, (j) {
            String letter = (j < currentGuess.length) ? currentGuess[j] : '';
            return Container(
              margin: const EdgeInsets.all(4),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            );
          }),
        ));
      } else {
        // Empty rows
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(wordLength, (j) {
            return Container(
              margin: const EdgeInsets.all(4),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ));
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    );
  }

  Widget buildKeyboard() {
    final screenWidth = MediaQuery.of(context).size.width;
    double keySpacing = 4.0;
    double horizontalPadding = 16.0;
    final availableWidth = screenWidth - 2 * horizontalPadding;

    // Always use the first row's key count for sizing all keys
    final keysInFirstRow = turkishQKeyboardRows[0].length;
    final totalSpacing = keySpacing * (keysInFirstRow + 1);
    final keyWidth = (availableWidth - totalSpacing) / keysInFirstRow;
    final keyHeight = keyWidth * 1.2;

    List<Widget> rows = [];
    for (var row in turkishQKeyboardRows) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row.map((l) {
          Color? bg;
          switch (keyboardStatus[l]) {
            case LetterFeedback.correct:
              bg = Colors.green;
              break;
            case LetterFeedback.present:
              bg = Colors.amber;
              break;
            case LetterFeedback.absent:
              bg = Colors.grey[400];
              break;
            default:
              bg = Colors.grey[100];
          }
          return Padding(
            padding: EdgeInsets.all(keySpacing / 2),
            child: SizedBox(
              width: keyWidth,
              height: keyHeight,
              child: ElevatedButton(
                onPressed: (gameOver || isLoading)
                    ? null
                    : () => onLetter(l),
                child: Text(l, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                ),
              ),
            ),
          );
        }).toList(),
      ));
    }
    // Add backspace and enter row, make them wider but keep key height
    rows.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(keySpacing / 2),
          child: SizedBox(
            width: keyWidth * 1.5,
            height: keyHeight,
            child: ElevatedButton(
              onPressed: onBackspace,
              child: const Icon(Icons.backspace_outlined),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(keySpacing / 2),
          child: SizedBox(
            width: keyWidth * 2,
            height: keyHeight,
            child: ElevatedButton(
              onPressed: onEnter,
              child: const Text('ENTER'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
            ),
          ),
        ),
      ],
    ));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Türkçe Wordle'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildBoard(),
          const SizedBox(height: 16),
          if (!gameOver) buildKeyboard(),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(message, style: const TextStyle(fontSize: 18, color: Colors.red)),
            ),
          if (gameOver)
            ElevatedButton(
              onPressed: loadWords,
              child: const Text('Yeniden Başla'),
            ),
        ],
      ),
    );
  }
}

enum LetterFeedback { correct, present, absent }
