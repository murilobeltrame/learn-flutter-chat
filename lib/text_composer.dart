import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {

  TextComposer(this.sendMessage);

  final Function({String text, File image}) sendMessage;

  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {

  TextEditingController _controller = TextEditingController();

  bool _isComposing = false;

  void _sendMessage(String text) {
    widget.sendMessage(text: text);
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo_camera),
            onPressed: () async {
              final File imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
              if (imageFile == null) return;
              widget.sendMessage(image: imageFile);
            },
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration.collapsed(hintText: 'Enviar uma mensagem...'),
              onChanged: (text){
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: _sendMessage,
              controller: _controller,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _isComposing ? () { _sendMessage(_controller.text); } : null,
          ),
        ],
      ),
    );
  }
}
