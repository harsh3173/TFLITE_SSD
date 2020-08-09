import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

class Model {
  File image;
  List recognitions;

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
        model: "assets/tflite/detect.tflite",
        labels: "assets/tflite/labelmap.txt",
        useGpuDelegate: true,
        numThreads: 2,
      );

      Fluttertoast.showToast(
          msg: 'Model Loaded Successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          fontSize: 16.0);
    } on PlatformException {
      print('Failed to load model.');
      Fluttertoast.showToast(
          msg: 'Failed to load model.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  Future ssdMobileNet(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );

    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
    print('SSD Mobilenet');
    return recognitions;
  }

// Boxes to render on the screen after result!!!
  List<Widget> renderBoxes(
      Size screen, List recognitions, double imageheight, double imagewidth,int acc) {
    if (recognitions == null) return [];
    if (imageheight == null || imagewidth == null) return [];

    print(recognitions);
    double factorX = screen.width;
    double factorY = imageheight / imagewidth * screen.width;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return recognitions.map(
      (re) {
        return Positioned(
          left: re["rect"]["x"] * factorX,
          top: re["rect"]["y"] * factorY,
          width: re["rect"]["w"] * factorX,
          height: re["rect"]["h"] * factorY,
          child: Container(
            decoration: re["confidenceInClass"] * 100 > acc // Only for above 50%
                ? BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                  )
                : BoxDecoration(),
            child: re["confidenceInClass"] * 100 > acc//Only for images greater than 50%
                ? Text(
                    "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(2)}%",
                    style: TextStyle(
                      backgroundColor: Colors.blue,
                      color: Colors.white,
                      fontSize: 15.0,
                    ),
                  )
                : Text(''),
          ),
        );
      },
    ).toList();
  }
}
