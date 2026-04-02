import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: TODOList());
  }
}

class TODOList extends StatefulWidget {
  const TODOList({super.key});

  @override
  State<TODOList> createState() => _TODOListState();
}

class _TODOListState extends State<TODOList> {
  List task = [];
  TextEditingController taskController = TextEditingController();

  void addtask() {
    setState(() {
      task.add({"text": taskController.text});
      taskController.clear();
    });
  }

  void delete(int index) {
    setState(() {
      task.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "TODO LIST",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Icon(Icons.menu, color: Colors.white),
        actions: [
          Icon(Icons.notifications, color: Colors.white),
          SizedBox(width: 10),
          Icon(Icons.account_circle_rounded, color: Colors.white),
        ],
        actionsPadding: EdgeInsets.all(10),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter Task",
                labelStyle: TextStyle(color: Colors.black),
              ),
              controller: taskController,
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: addtask,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.lightGreenAccent,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            child: Text("Add Tasks"),
          ),
          SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder:
                  (context, index) => Stack(
                children: [
                  Transform.rotate(
                    angle: 0.05,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                          Colors.primaries[DateTime.now().millisecond %
                              Colors.primaries.length][200],
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 0.5,
                              color: Colors.lightGreenAccent,
                              offset: Offset(4, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            task[index]["text"],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 60,
                    right: 40,
                    top: 10,
                    child: IconButton(
                      onPressed: () => delete(index),
                      icon: Icon(Icons.push_pin, color: Colors.white),
                    ),
                  ),
                ],
              ),
              itemCount: task.length,
            ),
          ),
        ],
      ),
    );
  }
}