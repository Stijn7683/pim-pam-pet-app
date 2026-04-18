import 'package:flutter/material.dart';
// import 'package:home_widget/home_widget.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'dart:convert';

import 'package:pimpampet/pimpampetwidget.dart';
import 'package:pimpampet/player_selection_screen.dart';
import 'dart:math';

import 'package:pimpampet/randomise.dart';
import 'package:pimpampet/settings_provider.dart';
import 'package:pimpampet/tests/interactive_sound_test_page.dart';
import 'package:provider/provider.dart';
//import 'package:pimpampet/tests/interactive_sound_test_page.dart';
//import 'package:pimpampet/soundtest.dart';

//import 'package:pimpampet/morphtest.dart';
//import 'morphtest2.dart';
//import 'morphtest3.dart';
//import 'package:pimpampet/tests/audio_package_tests.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => SettingsProvider(),
    child: const MyApp(),
  ));
}

final lightTheme = ThemeData(
  colorScheme: .fromSeed(
    seedColor: Colors.deepPurple
  ),
);

final darkTheme = ThemeData(
  colorScheme: .fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: .system,
      title: 'pim pam pet',
      home: //SoundLabPage() 
      const MyHomePage(title: 'pim pam pet'), //SoundLabPage() 
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String subject = '';
  String randomLetter = '';
  bool noArticle = false;

  void _randomise() {
    final (letter, subjectValue, noOne) = randomise();
    setState(() {
      randomLetter = letter;
      subject = subjectValue;
      noArticle = noOne;
    });

  }

  @override
  void initState() {
    _randomise();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: min(MediaQuery.of(context).size.width / 7 , 100),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('pim pam pet', style: Theme.of(context).textTheme.displayLarge?.
          copyWith(fontFamily: 'CarterOne').copyWith(fontSize: min(MediaQuery.of(context).size.width / 7 , 100))),
      ),
      
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Spacer(),
              SizedBox(width: MediaQuery.of(context).size.width ,),
              if (constraints.maxHeight > 220)
              GestureDetector(
                onTap: (){_randomise();},
                child: pimpampetWidget(subject, randomLetter, noArticle, false, context),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: min(200,constraints.maxHeight*.2)),
                child: (
                  ElevatedButton(
                    onPressed:() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PlayerSelectionScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      maximumSize: .new(100, 50),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ), 
                    child: Text('start'),
                  )
                ),
              ),
             
            ],
          );
        }
      ),
    );
  }

  
}