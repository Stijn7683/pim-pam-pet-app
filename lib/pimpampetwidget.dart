import 'package:flutter/material.dart';

Widget pimpampetWidget(String subject, String randomLetter, bool noArticle, bool large, context) {
  final textTheme = large ? Theme.of(context).textTheme.displayMedium : Theme.of(context).textTheme.displaySmall;
  return Column(
    mainAxisAlignment: .center,
    crossAxisAlignment: .center,
    children: [
      if (noArticle)
      Text('bedenk', style: TextStyle(height: 1.3),),
      if(!noArticle)
      Text('bedenk een', style: TextStyle(height: 1.3),),
      Text(
        subject,
        textAlign: TextAlign.center,
        style: textTheme?.copyWith(fontFamily: 'CarterOne').copyWith(height: 1.2),
      ),
      Text("dat begint met de letter", style: TextStyle(height: 1.3),),
      Text(
        randomLetter,
        textAlign: TextAlign.center,
        style: textTheme?.copyWith(fontFamily: 'CarterOne').copyWith(height: 1.2),
      ),              
    ],
  );
}