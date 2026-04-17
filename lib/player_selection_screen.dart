import 'package:flutter/material.dart';
import 'dart:math';
import 'package:pimpampet/playscreenv2.dart';
import 'package:pimpampet/settings_provider.dart';
import 'package:provider/provider.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final List<String> _items = List<String>.generate(5, (int index) => 'speler ${index+1 }');
  List<TextEditingController> textFieldControllers = List<TextEditingController>.generate(5, (int index) => TextEditingController());
  List<FocusNode> focusNodes = List<FocusNode>.generate(5, (int index) => FocusNode());

  @override
  void dispose() {
    for (var controller in textFieldControllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('voer namen in'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {}, // you won't really use this anymore
            icon: Icon(Icons.settings),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  enabled: false, // prevents closing on tap
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Text(
                        "instellingen:",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      );
                    },
                  ),
                ),
                PopupMenuItem<String>(
                  enabled: false, // prevents closing on tap
                  child: Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return CheckboxListTile(
                        title: Text(
                          "scores sorteren:",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        value: settings.sortScores,
                        controlAffinity: ListTileControlAffinity.trailing,
                        onChanged: (bool? newValue) {
                          context.read<SettingsProvider>().setSettings(null, newValue);
                        },
                      );
                    },
                  ),
                ),

                PopupMenuItem<String>(
                  enabled: false,
                  child: Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return CheckboxListTile(
                        title: Text(
                          "geluid:",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        value: settings.soundEnabled,
                        controlAffinity: ListTileControlAffinity.trailing,
                        onChanged: (bool? newValue) {
                          context.read<SettingsProvider>().setSettings(newValue, null);
                        },
                      );
                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            alignment: .topCenter,
            children: [
              Column(
                children: [
                  const SizedBox(height: 20),
                  Flexible(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      children: <Widget>[
                        for (int index = 0; index < _items.length; index += 1)
                          ListTile(
                            key: ValueKey(textFieldControllers[index]),
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: Icon(Icons.drag_handle),
                            ),
                            title: TextField(
                              controller: textFieldControllers[index],
                              focusNode: focusNodes[index],
                              decoration: InputDecoration(hintText: _items[index]),
                              onChanged: (value) {
                                _items[index] = value;
                              },
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  textFieldControllers[index].dispose();
                                  focusNodes[index].dispose();
                                  _items.removeAt(index);
                                  textFieldControllers.removeAt(index);
                                  focusNodes.removeAt(index);
                                });
                              }, 
                              child: Text('weghalen')
                            ),
                          ),
                      ],
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
              
                          final itemName = _items.removeAt(oldIndex);
                          _items.insert(newIndex, itemName);
              
                          final TextEditingController itemController = textFieldControllers.removeAt(oldIndex);
                          textFieldControllers.insert(newIndex, itemController);

                          final FocusNode itemFocusNode = focusNodes.removeAt(oldIndex);
                          focusNodes.insert(newIndex, itemFocusNode);
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 5,),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_items.contains('speler ${_items.length + 1}')) {
                          String newName = 'nieuwe speler';
                          int counter = 1;
                          while (_items.contains(newName)) {
                            counter++;
                            newName = 'nieuwe speler $counter';
                          }
                          _items.add(newName);
                        } else {
                          _items.add('speler ${_items.length + 1}');
                        }
                        textFieldControllers.add(TextEditingController());
                        FocusNode newFocusNode = FocusNode();
                        focusNodes.add(newFocusNode);
                        newFocusNode.requestFocus();
                      });
                    }, 
                    child: Text('naam toevoegen')),
                  SizedBox(height: min(200,constraints.maxHeight*.2) + 45)
                ],
              ),
              Positioned(
                bottom: min(200,constraints.maxHeight*.2),
                child: ElevatedButton(
                  onPressed:() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Playscreen2(names: _items,),)
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
                ),
              )
            ],
          );
        }
      )
    );
  }
}
