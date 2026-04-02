import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      print("ERROR: No user logged in!");
      return "";
    }
    return user.uid;
  }

  CollectionReference get userTasksCollection {
    if (userId.isEmpty) {
      throw Exception("User not logged in");
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks');
  }

  // Load tasks from Firestore
  Future<List<Map<String, dynamic>>> loadTasks() async {
    try {
      if (userId.isEmpty) return [];

      QuerySnapshot snapshot = await userTasksCollection
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'text': data['text'] ?? '',
          'completed': data['completed'] ?? false,
          'priority': data['priority'] ?? 'medium',
          'createdAt': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print("Error loading tasks: $e");
      return [];
    }
  }

  // Add single task to Firestore
  Future<void> addSingleTask(String text, String priority, bool completed) async {
    try {
      if (userId.isEmpty) return;

      await userTasksCollection.add({
        'text': text,
        'completed': completed,
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Task added successfully to Firebase!");
    } catch (e) {
      print("Error adding task: $e");
      throw e;
    }
  }

  // Update single task in Firestore
  Future<void> updateSingleTask(String taskId, String newText, String newPriority) async {
    try {
      if (userId.isEmpty) return;

      await userTasksCollection.doc(taskId).update({
        'text': newText,
        'priority': newPriority,
      });
      print("Task updated successfully!");
    } catch (e) {
      print("Error updating task: $e");
      throw e;
    }
  }

  // Toggle task completion in Firestore
  Future<void> toggleTaskCompletion(String taskId, bool completed) async {
    try {
      if (userId.isEmpty) return;

      await userTasksCollection.doc(taskId).update({
        'completed': completed,
      });
      print("Task completion toggled!");
    } catch (e) {
      print("Error toggling task: $e");
      throw e;
    }
  }

  // Delete single task from Firestore
  Future<void> deleteSingleTask(String taskId) async {
    try {
      if (userId.isEmpty) return;

      await userTasksCollection.doc(taskId).delete();
      print("Task deleted successfully!");
    } catch (e) {
      print("Error deleting task: $e");
      throw e;
    }
  }

  // Clear all tasks from Firestore
  Future<void> clearAllTasks() async {
    try {
      if (userId.isEmpty) return;

      QuerySnapshot snapshot = await userTasksCollection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print("All tasks cleared!");
    } catch (e) {
      print("Error clearing tasks: $e");
      throw e;
    }
  }

  // Clear only pending tasks
// Add this to your firestore_service.dart if not present
  Future<void> clearPendingTasks() async {
    try {
      if (userId.isEmpty) return;

      QuerySnapshot snapshot = await userTasksCollection
          .where('completed', isEqualTo: false)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print("Pending tasks cleared!");
    } catch (e) {
      print("Error clearing pending tasks: $e");
      throw e;
    }
  }}