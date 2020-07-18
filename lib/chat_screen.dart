import 'dart:io';

import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  void _sendMessage({String text, File image}) async {

    Map<String, dynamic> data = {};

    if (image != null) {
      StorageUploadTask task = FirebaseStorage.instance.ref()
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(image);
      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      data['imageUrl'] = await taskSnapshot.ref.getDownloadURL();
    }

    if (text != null && text.isNotEmpty) data['text'] = text;

    Firestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        elevation: 0,
      ),
      body: TextComposer(_sendMessage),
    );
  }
}
