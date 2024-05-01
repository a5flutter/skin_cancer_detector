//import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;

class AIBloc extends Bloc<AIEvent, AIState> {
  AIBloc() : super(AIInitial()) {

    // Future<Uint8List> imageToBytesSync(Image image) async {
    //   ByteData? data = await image.toByteData();
    //   List<int> bytes = data?.buffer?.asUint8List() ?? [];
    //   return Uint8List.fromList(bytes);
    // }

    on<PerformImageRecognitionEvent>((event, emit) async {
      try {

        final ByteData bytes = await rootBundle.load(event.imagePath);
        final Uint8List list = bytes.buffer.asUint8List();

        img.Image? image = img.decodeImage(list, frame: 224);

        Uint8List byteData = image!.data!.toUint8List();
        //
        // List<dynamic>? recognitionResults = await Tflite.detectObjectOnBinary(binary: list,
        //   threshold: 0.5,
        // );
        print('list.length: ${list.length}, byteData.length: ${byteData.length}');
        var recognitionResults = await Tflite.runModelOnBinary(binary: byteData,//list,
        //     .detectObjectOnImage(
        //     path: event.imagePath,       // required
        //     model: "YOLO",
        //     imageMean: 127.5,
        //     imageStd: 127.5,
            numResults: 3,
            threshold: 0.05,       // defaults to 0.1
            // numResultsPerClass: 1,// defaults to 5
        //     asynch: true          // defaults to true
        );
        //print('recognitionResults.hashCode: ${recognitionResults.hashCode}');
        emit(AIImageRecognitionSuccess(recognitionResults: recognitionResults));
      } catch (e) {
        emit(AIError(message: 'Error performing image recognition: $e'));
      }
    });
  }
}

abstract class AIEvent {}

class PerformImageRecognitionEvent extends AIEvent {
  final String imagePath;

  PerformImageRecognitionEvent({required this.imagePath});
}

abstract class AIState {}

class AIInitial extends AIState {}

class AIImageRecognitionSuccess extends AIState {
  final List<dynamic>? recognitionResults;

  AIImageRecognitionSuccess({required this.recognitionResults});
}

class AIError extends AIState {
  final String message;

  AIError({required this.message});
}