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
  bool _uploading = false;

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
      'time': Timestamp.now(),
    };

    if (image != null) {
      StorageUploadTask task = FirebaseStorage.instance.ref()
          .child('${DateTime.now().millisecondsSinceEpoch.toString()}${user.uid}')
          .putFile(image);
      setState(() {
        _uploading = true;
      });
      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      data['imageUrl'] = await taskSnapshot.ref.getDownloadURL();
      setState(() {
        _uploading = false;
      });
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
            return ChatMessage(
              documents[index].data,
              documents[index].data['uid'] == _currentUser?.uid
            );
          },
        );
    }
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        print('User changed to $_currentUser');
        _currentUser = user;
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentUser != null ? 'Chatting as ${_currentUser.displayName}' : 'Chat App'),
        elevation: 0,
        actions: <Widget>[
          _currentUser != null ?
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                googleSignIn.signOut();
                _scaffoldKey.currentState.showSnackBar(SnackBar(
                  content: Text('Saiu com sucesso'),
                ));
              },
            ) :
            Container()
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: Firestore.instance.collection('messages').orderBy('time').snapshots(),
              builder: _itemsBuilder,
            ),
          ),
          _uploading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      )
    );
  }
}
