import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todolist/screens/firestore_service.dart';
import 'package:todolist/screens/login_page.dart';

class TODOList extends StatefulWidget {
  const TODOList({super.key});

  @override
  State<TODOList> createState() => _TODOListState();
}

class _TODOListState extends State<TODOList> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> task = [];
  TextEditingController taskController = TextEditingController();
  TextEditingController editController = TextEditingController();
  String searchQuery = "";
  String filterType = "all";
  bool isLoading = true;
  String selectedPriority = "medium";
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadTasksFromFirebase();
  }

  @override
  void dispose() {
    taskController.dispose();
    editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> loadTasksFromFirebase() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedTasks = await _firestoreService.loadTasks();

      setState(() {
        task = loadedTasks.map((t) => {
          "text": t['text'],
          "completed": t['completed'],
          "createdAt": t['createdAt'],
          "priority": t['priority'],
          "id": t['id'],
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading tasks"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void addtask() async {
    if (taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a task"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await _firestoreService.addSingleTask(
        taskController.text.trim(),
        selectedPriority,
        false,
      );

      await loadTasksFromFirebase();
      taskController.clear();
      _focusNode.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Task added successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding task. Check internet!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void deleteTaskWithId(String taskId) async {
    try {
      await _firestoreService.deleteSingleTask(taskId);
      await loadTasksFromFirebase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Task deleted"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting task"), backgroundColor: Colors.red),
      );
    }
  }

  void confirmDelete(String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Task"),
          content: Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                deleteTaskWithId(taskId);
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void toggleComplete(String taskId, bool currentStatus) async {
    try {
      await _firestoreService.toggleTaskCompletion(taskId, !currentStatus);
      await loadTasksFromFirebase();
    } catch (e) {
      // Handle error silently
    }
  }

  void editTask(String taskId, String currentText, String currentPriority) async {
    editController.text = currentText;
    String tempPriority = currentPriority;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Edit Task", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Update your task",
                    ),
                    autofocus: true,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tempPriority,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Priority",
                    ),
                    items: ['low', 'medium', 'high'].map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: getPriorityColor(priority),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(priority.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        tempPriority = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    editController.clear();
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (editController.text.trim().isNotEmpty) {
                      try {
                        await _firestoreService.updateSingleTask(
                          taskId,
                          editController.text.trim(),
                          tempPriority,
                        );
                        await loadTasksFromFirebase();
                        Navigator.pop(context);
                        editController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Task updated!"),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error updating task"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> get filteredTasks {
    List<Map<String, dynamic>> filtered = task.where((taskItem) {
      bool matchesSearch = taskItem["text"]
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (filterType == "completed") {
        matchesStatus = taskItem["completed"] == true;
      } else if (filterType == "pending") {
        matchesStatus = taskItem["completed"] == false;
      }

      return matchesSearch && matchesStatus;
    }).toList();

    return filtered;
  }

  int get completedCount {
    return task.where((t) => t["completed"] == true).length;
  }

  int get pendingCount {
    return task.where((t) => t["completed"] == false).length;
  }

  Color getPriorityColor(String priority) {
    switch(priority) {
      case "high":
        return Colors.red[200]!;
      case "low":
        return Colors.green[200]!;
      default:
        return Colors.orange[200]!;
    }
  }

  Future<void> clearAllTasks() async {
    try {
      await _firestoreService.clearAllTasks();
      await loadTasksFromFirebase();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> clearPendingTasks() async {
    try {
      await _firestoreService.clearPendingTasks();
      await loadTasksFromFirebase();
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return LoginPage();
                    },
                  ),
                );
              }
            },
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
        actionsPadding: EdgeInsets.all(10),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "🔍 Search tasks...",
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.white, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "📋 Total: ${task.length} tasks",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "✅ $completedCount  •  ⏳ $pendingCount",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text("All", style: TextStyle(fontSize: 12)),
                      selected: filterType == "all",
                      onSelected: (selected) {
                        setState(() {
                          filterType = "all";
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue[100],
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text("Completed", style: TextStyle(fontSize: 12)),
                      selected: filterType == "completed",
                      onSelected: (selected) {
                        setState(() {
                          filterType = "completed";
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.green[100],
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text("Pending", style: TextStyle(fontSize: 12)),
                      selected: filterType == "pending",
                      onSelected: (selected) {
                        setState(() {
                          filterType = "pending";
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.orange[100],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Text("Priority:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(width: 10),
                  Expanded(child: _buildPriorityButton("low", "Low", Colors.green)),
                  SizedBox(width: 8),
                  Expanded(child: _buildPriorityButton("medium", "Medium", Colors.orange)),
                  SizedBox(width: 8),
                  Expanded(child: _buildPriorityButton("high", "High", Colors.red)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                focusNode: _focusNode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Task",
                  labelStyle: TextStyle(color: Colors.black, fontSize: 14),
                  suffixIcon: taskController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      taskController.clear();
                    },
                  )
                      : null,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: taskController,
                onSubmitted: (value) {
                  addtask();
                },
              ),
            ),
            ElevatedButton(
              onPressed: addtask,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.lightGreenAccent,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                minimumSize: Size(120, 40),
              ),
              child: Text("Add Tasks", style: TextStyle(fontSize: 14)),
            ),
            SizedBox(height: 8),
            if (filteredTasks.isEmpty)
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        searchQuery.isNotEmpty ? Icons.search_off : Icons.check_circle_outline,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 12),
                      Text(
                        searchQuery.isNotEmpty
                            ? "No tasks match"
                            : filterType != "all"
                            ? "No ${filterType} tasks"
                            : "No tasks yet!",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 6),
                      if (filteredTasks.isEmpty && searchQuery.isEmpty && filterType == "all")
                        Text(
                          "Add your first task above ✨\nTasks will be saved permanently!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      if (searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              searchQuery = "";
                            });
                          },
                          child: Text("Clear search", style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final taskItem = filteredTasks[index];
                      final String taskId = taskItem['id'] ?? '';

                      return Dismissible(
                        key: Key(taskItem["text"].toString() + index.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          deleteTaskWithId(taskId);
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.delete, color: Colors.white, size: 20),
                        ),
                        child: GestureDetector(
                          onTap: () => toggleComplete(taskId, taskItem["completed"]),
                          onLongPress: () => editTask(taskId, taskItem["text"], taskItem["priority"]),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: taskItem["completed"]
                                  ? Colors.grey[400]
                                  : getPriorityColor(taskItem["priority"]),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 2,
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (taskItem["priority"] != "medium")
                                          Icon(
                                            taskItem["priority"] == "high"
                                                ? Icons.priority_high
                                                : Icons.low_priority,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                        SizedBox(height: 6),
                                        Flexible(
                                          child: Text(
                                            taskItem["text"],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              decoration: taskItem["completed"]
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (taskItem["completed"]) ...[
                                          SizedBox(height: 4),
                                          Icon(Icons.check_circle, size: 18, color: Colors.white70),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    onPressed: () => editTask(taskId, taskItem["text"], taskItem["priority"]),
                                    icon: Icon(Icons.edit, color: Colors.white, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: IconButton(
                                    onPressed: () => confirmDelete(taskId),
                                    icon: Icon(Icons.delete_outline, color: Colors.white70, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      taskItem["priority"][0].toUpperCase(),
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: filteredTasks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: task.isNotEmpty
          ? FloatingActionButton.small(
        onPressed: () {
          if (completedCount == task.length) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Clear All Tasks", style: TextStyle(fontSize: 16)),
                  content: Text("All tasks are completed! Clear them?", style: TextStyle(fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        clearAllTasks();
                        Navigator.pop(context);
                      },
                      child: Text("Clear All", style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                );
              },
            );
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Delete Pending", style: TextStyle(fontSize: 16)),
                  content: Text("Delete all pending tasks?", style: TextStyle(fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        clearPendingTasks();
                        Navigator.pop(context);
                      },
                      child: Text("Delete", style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                );
              },
            );
          }
        },
        backgroundColor: Colors.red,
        child: Icon(completedCount == task.length ? Icons.delete_sweep : Icons.clear_all, size: 20),
      )
          : null,
    );
  }

  Widget _buildPriorityButton(String value, String label, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPriority = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selectedPriority == value ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedPriority == value ? color : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selectedPriority == value ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}