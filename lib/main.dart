import 'dart:convert';
import 'dart:ffi';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorites() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }

    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = UserPage();
        break;
      case 3:
        page = SeparacaoPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people),
                    label: Text('Users'),
                  ),
                  NavigationRailDestination(
                      icon: Icon(Icons.warehouse), label: Text('Separação'))
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorites();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(children: [
      Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have' ' ${appState.favorites.length} favorites')),
      for (var pair in appState.favorites)
        ListTile(
          leading: IconButton(
            icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'),
            color: theme.colorScheme.primary,
            onPressed: () {
              appState.removeFavorite(pair);
            },
          ),
          title: Text(pair.asLowerCase),
        )
    ]);
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}

class UserPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Future<List<User>> futureUser;

  @override
  void initState() {
    super.initState();

    futureUser = getUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: getUser(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(snapshot.data![index].name,
                        style: const TextStyle(fontSize: 18)),
                  );
                }),
          );
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

class SeparacaoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SeparacaoPageState();
}

class _SeparacaoPageState extends State<SeparacaoPage> {
  RegExp _digitRegex = RegExp("[0-9]+");
  bool isANumber = true;
  bool isValidForm = false;
  var _numberForm = GlobalKey<FormState>();

  void setValidator(valid) {
    setState(() {
      isANumber = valid;
    });
  }

  @override
  Widget build(BuildContext context) {
    var initialText = 'Tr TR 01 01 00';
    return Center(
      child: Form(
          key: _numberForm,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Transporte',
                      labelStyle: TextStyle(fontSize: 25),
                      border: InputBorder.none),
                  enabled: false,
                  initialValue: initialText,
                ),
              ),
              SizedBox(
                width: 250,
                height: 60,
                child: TextFormField(
                    keyboardType: TextInputType.number,
                    validator: (inputValue) {
                      if (inputValue!.isEmpty ||
                          !_digitRegex.hasMatch(inputValue)) {
                        return "Informe valores numéricos";
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (value) {
                      print("Go button is clicked");
                    },
                    decoration: const InputDecoration(
                        labelText: 'Etiqueta',
                        helperText: ' ',
                        filled: true,
                        border: OutlineInputBorder(),
                        errorBorder: OutlineInputBorder(),
                        errorStyle: TextStyle(color: Colors.red))),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: 100,
                  child: ElevatedButton(
                      onPressed: () {
                        if (_numberForm.currentState!.validate()) {
                          setState(() {
                            isValidForm = true;
                          });
                        } else {
                          setState(() {
                            isValidForm = false;
                          });
                        }
                      },
                      child: Text('Save')),
                ),
              )
            ],
          )),
    );
  }
}

Future<List<User>> getUser() async {
  var url = Uri.parse('http://localhost:8081/users');
  var response = await http.get(url);

  List jsonResponse = json.decode(response.body);
  return jsonResponse.map((data) => User.fromJson(data)).toList();
}

class User {
  final int id;
  final String name;

  const User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name']);
  }
}
