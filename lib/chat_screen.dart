import 'dart:io';

import 'package:chat/chat_message.dart';
import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  FirebaseUser _currentUser;

  final GoogleSignIn googleSignIn = GoogleSignIn();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _sendMessage({String text, File image}) async {

    final FirebaseUser user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Não foi possível fazer o login. Tente novamente'),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      'uid': user.uid,
      'senderName': user.displayName,
      'senderPhotoUrl': user.photoUrl,
    };

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

  Future<FirebaseUser> _getUser() async {

    if (_currentUser != null) return _currentUser;

    try {
      final GoogleSignInAccount googleAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuthentication = await googleAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
          idToken: googleAuthentication.idToken,
          accessToken: googleAuthentication.accessToken,
      );
      final AuthResult result = await FirebaseAuth.instance.signInWithCredential(credential);
      return result.user;
    } catch (error) {
      return null;
    }
  }

  Widget _itemsBuilder (BuildContext context, AsyncSnapshot snapshot) {

    switch (snapshot.connectionState) {
      case ConnectionState.waiting:
      case ConnectionState.none:
        return Center(
          child: CircularProgressIndicator(),
        );
      default:
        List<DocumentSnapshot> documents = snapshot.data.documents
          .reversed
          .toList();
        return ListView.builder(
          itemCount: documents.length,
          reverse: true,
          itemBuilder: (context, index) {
            return ChatMessage(documents[index].data, true);
          },
        );
    }
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Chat'),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: Firestore.instance.collection('messages').snapshots(),
              builder: _itemsBuilder,
            ),
          ),
          TextComposer(_sendMessage),
        ],
      )
    );
  }
}
