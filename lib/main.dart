import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FridgeLens',
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
      home: const MyHomePage(title: 'FridgeLens Firebase Test'),
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
  String _authStatus = 'Not tested';
  String _firestoreStatus = 'Not tested';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Test user credentials - replace with your test user if needed
  final String _testEmail = 'test@example.com';
  final String _testPassword = 'Test123!';

  Future<void> _testFirebaseAuth() async {
    setState(() {
      _authStatus = 'Testing Auth...';
    });

    try {
      // Try to create a test user
      try {
        await _auth.createUserWithEmailAndPassword(
          email: _testEmail,
          password: _testPassword,
        );
        setState(() {
          _authStatus = 'User created successfully!';
        });
      } catch (e) {
        // If user already exists, try to sign in
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          try {
            await _auth.signInWithEmailAndPassword(
              email: _testEmail,
              password: _testPassword,
            );
            setState(() {
              _authStatus = 'User signed in successfully!';
            });
          } catch (signInError) {
            setState(() {
              _authStatus = 'Auth Error: ${signInError.toString()}';
            });
          }
        } else {
          setState(() {
            _authStatus = 'Auth Error: ${e.toString()}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _authStatus = 'Auth Error: ${e.toString()}';
      });
    }
  }

  Future<void> _testFirestore() async {
    setState(() {
      _firestoreStatus = 'Testing Firestore...';
    });

    try {
      // Add a test document to Firestore
      await _firestore.collection('test').doc('test_doc').set({
        'timestamp': DateTime.now().toString(),
        'message': 'FridgeLens test connection',
      });

      // Read the document back to verify
      final docSnapshot = await _firestore
          .collection('test')
          .doc('test_doc')
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _firestoreStatus =
              'Firestore connected successfully!\nData: ${docSnapshot.data()}';
        });
      } else {
        setState(() {
          _firestoreStatus = 'Firestore Error: Document does not exist';
        });
      }
    } catch (e) {
      setState(() {
        _firestoreStatus = 'Firestore Error: ${e.toString()}';
      });
    }
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
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            //
            // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
            // action in the IDE, or press "p" in the console), to see the
            // wireframe for each widget.
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 30),

              const Text(
                'Test Firebase Authentication:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _testFirebaseAuth,
                child: const Text('Test Auth'),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _authStatus.contains('successfully')
                      ? Colors.green.withOpacity(0.1)
                      : _authStatus.contains('Error')
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _authStatus,
                  style: TextStyle(
                    color: _authStatus.contains('successfully')
                        ? Colors.green
                        : _authStatus.contains('Error')
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                'Test Firestore Database:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _testFirestore,
                child: const Text('Test Firestore'),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _firestoreStatus.contains('successfully')
                      ? Colors.green.withOpacity(0.1)
                      : _firestoreStatus.contains('Error')
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _firestoreStatus,
                  style: TextStyle(
                    color: _firestoreStatus.contains('successfully')
                        ? Colors.green
                        : _firestoreStatus.contains('Error')
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
