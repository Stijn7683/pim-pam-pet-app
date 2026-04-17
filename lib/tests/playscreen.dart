import 'package:flutter/material.dart';
import 'dart:math';

import 'package:pimpampet/pimpampetwidget.dart';

class Playscreen extends StatefulWidget {
  const Playscreen({super.key, required this.names});

  final List<String> names;

  @override
  State<Playscreen> createState() => _PlayscreenState();
}

class _PlayscreenState extends State<Playscreen> {
  String subject = '';
  String randomLetter = '';
  final List<String> onderwerpen = ['een natuurproduct', 'een bloem', 'een vis', 'een deel van het menselijk lichaam', 'keuken gereedschap', 'jongensnaam', 'meisjesnaam', 'stad in Europa', 'iets in een boerderij', 'een dier', 'een schilder of beeldhouwer',  'groente', 'schrijver of dichter', 'een berg of bergketen', 'een kanaal of rivier', 'een muziekinstrument', 'een kledingstuk', 'een boom', 'voedsel voor mensen', 'gereedschap', 'huiskamer voorwerp', 'een vogel', 'een schoolvak'];
  List<String> names = [];
  List<int> scores = [];
  void _incrementCounter() {
    setState(() {
      randomLetter = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',][(Random().nextInt(26))];
      subject = onderwerpen[(Random().nextInt(onderwerpen.length))];
    });
  }

  @override
  void initState() {
    _incrementCounter();
    names = widget.names;
    print(names);
    scores = List<int>.generate(names.length, (int index) => 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('pim pam pet'),
      ),
      body: Column(
        mainAxisAlignment: .center,
        children: [
          pimpampetWidget(subject, randomLetter, false, true, context),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: names.length,
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        scores[index] += 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Name (left aligned)
                          Expanded(
                            child: Text(
                              names[index],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 24),
                            ),
                          ),

                          // Score (right aligned)
                          Text(
                            scores[index].toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
