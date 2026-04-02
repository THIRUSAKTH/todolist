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

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  bool isLogin = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final taskController = TextEditingController();

  ////////////////// AUTH //////////////////

  Future<void> authenticate() async {
    try {
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  ////////////////// TASK //////////////////

  CollectionReference get taskRef =>
      db.collection("users").doc(auth.currentUser!.uid).collection("tasks");

  Future<void> addTask() async {
    if (taskController.text.isEmpty) return;

    await taskRef.add({
      "text": taskController.text,
      "time": Timestamp.now(),
    });

    taskController.clear();
  }

  Future<void> deleteTask(String id) async {
    await taskRef.doc(id).delete();
  }

  ////////////////// UI //////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: auth.currentUser == null ? authUI() : todoUI(),
    );
  }

  ////////////////// AUTH UI //////////////////

  Widget authUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff4facfe), Color(0xff00f2fe)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                isLogin ? "Welcome Back 👋" : "Create Account 🚀",
                style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        hintText: "Email",
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        hintText: "Password",
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: authenticate,
                      child: Text(isLogin ? "Login" : "Signup"),
                    ),

                    TextButton(
                      onPressed: () {
                        setState(() => isLogin = !isLogin);
                      },
                      child: Text(isLogin
                          ? "Create Account"
                          : "Already have account? Login"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ////////////////// TODO UI //////////////////

  Widget todoUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await auth.signOut(),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Add Task"),
              content: TextField(
                controller: taskController,
                decoration: const InputDecoration(hintText: "Task"),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    addTask();
                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                )
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder(
        stream: taskRef.orderBy("time").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: tasks.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (_, index) {
              final data = tasks[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5)
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        data['text'],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => deleteTask(data.id),
                        child: const Icon(Icons.close, color: Colors.red),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}