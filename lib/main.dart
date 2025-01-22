import 'package:flutter/material.dart';
import 'package:komiku/screen/bacakomik.dart';
import 'package:komiku/screen/carikomik.dart';
import 'package:komiku/screen/kategori.dart';
import 'package:komiku/screen/komikfavorit.dart';
import 'package:komiku/screen/mykomik.dart';
import 'package:komiku/screen/tambahkomik.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/home.dart';
import 'screen/login.dart';

String active_user = "";
Future<String> checkUser() async {
  final prefs = await SharedPreferences.getInstance();
  String user_name = prefs.getString("user_name") ?? '';
  return user_name;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  checkUser().then((String result) {
    if (result == '')
      runApp(MyLogin());
    else {
      active_user = result;
      runApp(MyApp());
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Komiku',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Komiku'),
      routes: {
        'carikomik': (context) => const CariKomik(),
        'kategori': (context) => const Kategori(),
        'tambahkomik': (context) => const TambahKomik(),
        'mykomik': (context) => const MyKomik(),
        'komikfavorit': (context) => const KomikFavorit(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _user_name = "";
  int _currentIndex = 0;
  final List<Widget> _screens = [
    Home(),
    CariKomik(),
    Kategori(),
    TambahKomik()
  ];
  final List<String> _title = [
    'Home',
    'Cari',
    'Kategori',
    'Komik Saya',
    'Tambah Komik',
    'Komik Favorit'
  ];

  void doLogout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("user_id");
    prefs.remove("user_name");
    main();
  }

  @override
  void initState() {
    checkUser().then((value) => setState(
          () {
            _user_name = value;
            active_user = value;
          },
        ));
  }

  Widget myDrawer() {
    return Drawer(
      elevation: 16.0,
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(_user_name.isNotEmpty ? _user_name : "Guest"),
            accountEmail: Text(
              _user_name.isNotEmpty
                  ? "${_user_name}@gmail.com"
                  : "guest@gmail.com",
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
            ),
          ),
          ListTile(
              title: const Text("Cari Komik"),
              leading: const Icon(Icons.search_rounded),
              onTap: () {
                Navigator.pushNamed(context, "carikomik");
              }),
          ListTile(
              title: const Text("Kategori"),
              leading: const Icon(Icons.category),
              onTap: () {
                Navigator.pushNamed(context, "kategori");
              }),
          ListTile(
              title: const Text("Komik Saya"),
              leading: const Icon(Icons.book_rounded),
              onTap: () {
                Navigator.pushNamed(context, "mykomik");
              }),
          ListTile(
              title: const Text("Komik Favorit"),
              leading: const Icon(Icons.favorite),
              onTap: () {
                Navigator.pushNamed(context, "komikfavorit");
              }),
          ListTile(
              title: const Text("Tambah Komik"),
              leading: const Icon(Icons.add_circle_rounded),
              onTap: () {
                Navigator.pushNamed(context, "tambahkomik");
              }),
          ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout),
              onTap: () {
                doLogout();
              }),
        ],
      ),
    );
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
          title: Text(_title[_currentIndex])),
      drawer: myDrawer(),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: _screens[_currentIndex],

        //   child: Column(
        //     // Column is also a layout widget. It takes a list of children and
        //     // arranges them vertically. By default, it sizes itself to fit its
        //     // children horizontally, and tries to be as tall as its parent.
        //     //
        //     // Column has various properties to control how it sizes itself and
        //     // how it positions its children. Here we use mainAxisAlignment to
        //     // center the children vertically; the main axis here is the vertical
        //     // axis because Columns are vertical (the cross axis would be
        //     // horizontal).
        //     //
        //     // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
        //     // action in the IDE, or press "p" in the console), to see the
        //     // wireframe for each widget.
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: <Widget>[
        //       const Text(
        //         'Sandiarta Asburhalim Firmansyah 160421110',
        //         style: TextStyle(fontSize: 45),
        //         textAlign: TextAlign.center,
        //       ),
        //       Text(
        //         '$_counter',
        //         style: Theme.of(context).textTheme.headlineMedium,
        //       ),
        //       Text(
        //         '$_emote',
        //         style: Theme.of(context).textTheme.headlineMedium,
        //       ),
        //     ],
        //   ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      // currentIndex: _currentIndex,
      // selectedItemColor: Colors.teal,
      // unselectedItemColor: Colors.grey,
      // showUnselectedLabels: true,
      // items: const [
      //   BottomNavigationBarItem(
      //     label: "Home",
      //     icon: Icon(Icons.home),
      //   ),
      //   BottomNavigationBarItem(
      //     label: "Cari",
      //     icon: Icon(Icons.search_rounded),
      //   ),
      //   BottomNavigationBarItem(
      //     label: "Kategori",
      //     icon: Icon(Icons.category),
      //   ),
      //   BottomNavigationBarItem(
      //     label: "Tambah",
      //     icon: Icon(Icons.add_circle_rounded),
      //   ),
      // ],
      // onTap: (int index) {
      //   setState(() {
      //     _currentIndex = index;
      //   });
      //   if (index != 0) {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) {
      //         return CariKomik()..isFromBottomNavBar = true;
      //       },
      //     ),
      //   );
      // }
      // },
      // ),
    );
  }
}
