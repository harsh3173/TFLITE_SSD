import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'model.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(new App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File _image;
  List _recognitions;
  double _imageHeight;
  double _imageWidth;
  bool _loadingSpinner = false;
  int accuracy = 50; // % minimum accuracy required in integer

  Future predictImagePicker() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _loadingSpinner = true;
    });
    predictImage(image);
  }

  Future predictImage(File image) async {
    if (image == null) return;
    var recognitions = await Model().ssdMobileNet(image);

    setState(() {
      _recognitions = recognitions;
    });

    new FileImage(image).resolve(new ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          setState(() {
            _imageHeight = info.image.height.toDouble();
            _imageWidth = info.image.width.toDouble();
          });
        },
      ),
    );

    setState(() {
      _image = image;
      _loadingSpinner = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _loadingSpinner = true;

    Model().loadModel().then((val) {
      setState(() {
        _loadingSpinner = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size; // Get Screen Size
    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null
          ? Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(child: Text('No Image selected.')),
          )
          : Image.file(_image),
    ));
    // Render Boxes
    stackChildren.addAll(
      Model().renderBoxes(
          size, _recognitions, _imageHeight, _imageWidth, accuracy),
    );

    // Circular Progress Indicator
    if (_loadingSpinner) {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.grey),
        opacity: 0.3,
      ));
      stackChildren.add(
        const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TFlite App'),
      ),
      body: Stack(
        children: stackChildren,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: predictImagePicker,
        tooltip: 'Pick Image',
        child: Icon(Icons.image),
      ),
    );
  }
}
