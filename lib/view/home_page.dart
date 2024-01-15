import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:base_todolist/main.dart';
import 'package:base_todolist/model/item_list.dart'; // Import the file where your ItemList widget is defined
import 'login_page.dart';
import 'register_page.dart'; // Import the file where your RegisterPage widget is defined

class _HomePageState extends State<HomePage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  bool isComplete = false;

  // Add a loading indicator for addTodo
  bool _addingTodo = false;

  // ... (existing functions)

  Future<void> addTodo() async {
    setState(() {
      _addingTodo = true;
    });

    try {
      await todoCollection.add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isComplete': isComplete,
        'uid': _auth.currentUser!.uid,
      });
      getTodo();
    } catch (error) {
      final snackbar = SnackBar(content: Text("Error: $error"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } finally {
      setState(() {
        _addingTodo = false;
      });
    }
  }

  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    CollectionReference todoCollection = _firestore.collection('Todos');
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
          // ... (existing code)
          ),
      body: Column(
        children: [
          // ... (existing code)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _searchController.text.isEmpty
                  ? _firestore
                      .collection('Todos')
                      .where('uid', isEqualTo: user!.uid)
                      .snapshots()
                  : searchResultsFuture != null
                      ? searchResultsFuture!
                          .asStream()
                          .cast<QuerySnapshot<Map<String, dynamic>>>()
                      : Stream.empty(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<Todo> listTodo = snapshot.data!.docs.map((document) {
                  final data = document.data();
                  // ... (existing code)
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: listTodo.length,
                  itemBuilder: (context, index) {
                    return ItemList(
                      todo: listTodo[index],
                      transaksiDocId: snapshot.data!.docs[index].id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Tambah Todo'),
              content: SizedBox(
                width: 200,
                height: 100,
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(hintText: 'Judul todo'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(hintText: 'Deskripsi todo'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Batalkan'),
                  onPressed: () => Navigator.pop(context),
                ),
                // Disable the button or show loading indicator while adding todo
                ElevatedButton(
                  onPressed: _addingTodo
                      ? null
                      : () {
                          addTodo();
                          cleartext();
                          Navigator.pop(context);
                        },
                  child: Text('Tambah'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
