import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_cancer_detector/bloc/ai_bloc.dart';
import 'package:tflite/tflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    Tflite.close();
    Tflite.loadModel(
        model: 'assets/model_weight/model224.tflite',
        /*
    nv
Melanocytic nevi are benign neoplasms of melanocytes and appear in a myriad of variants, which all are included in our series. The variants may differ significantly from a dermatoscopic point of view.
[6705 images]

mel
Melanoma is a malignant neoplasm derived from melanocytes that may appear in different variants. If excised in an early stage it can be cured by simple surgical excision. Melanomas can be invasive or non-invasive (in situ). We included all variants of melanoma including melanoma in situ, but did exclude non-pigmented, subungual, ocular or mucosal melanoma.
[1113 images]

bkl
"Benign keratosis" is a generic class that includes seborrheic ker- atoses ("senile wart"), solar lentigo - which can be regarded a flat variant of seborrheic keratosis - and lichen-planus like keratoses (LPLK), which corresponds to a seborrheic keratosis or a solar lentigo with inflammation and regression [22]. The three subgroups may look different dermatoscop- ically, but we grouped them together because they are similar biologically and often reported under the same generic term histopathologically. From a dermatoscopic view, lichen planus-like keratoses are especially challeng- ing because they can show morphologic features mimicking melanoma [23] and are often biopsied or excised for diagnostic reasons.
[1099 images]

bcc
Basal cell carcinoma is a common variant of epithelial skin cancer that rarely metastasizes but grows destructively if untreated. It appears in different morphologic variants (flat, nodular, pigmented, cystic, etc) [21], which are all included in this set.
[514 images]

akiec
Actinic Keratoses (Solar Keratoses) and intraepithelial Carcinoma (Bowen’s disease) are common non-invasive, variants of squamous cell car- cinoma that can be treated locally without surgery. Some authors regard them as precursors of squamous cell carcinomas and not as actual carci- nomas. There is, however, agreement that these lesions may progress to invasive squamous cell carcinoma - which is usually not pigmented. Both neoplasms commonly show surface scaling and commonly are devoid of pigment. Actinic keratoses are more common on the face and Bowen’s disease is more common on other body sites. Because both types are in- duced by UV-light the surrounding skin is usually typified by severe sun damaged except in cases of Bowen’s disease that are caused by human papilloma virus infection and not by UV. Pigmented variants exists for Bowen’s disease [19] and for actinic keratoses [20]. Both are included in this set.
[327 images]

vasc
Vascular skin lesions in the dataset range from cherry angiomas to angiokeratomas [25] and pyogenic granulomas [26]. Hemorrhage is also included in this category.
[142 images]

df
Dermatofibroma is a benign skin lesion regarded as either a benign proliferation or an inflammatory reaction to minimal trauma. It is brown often showing a central zone of fibrosis dermatoscopically [24].
     */
        labels: 'assets/model_weight/labels_skin_cancer.txt',
        numThreads: 10,
        isAsset: true,
        useGpuDelegate: false
    );
  } catch (e) {
    print('Error loading model: ${e}');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => AIBloc(),
        child: MyAIWidgetWrapper(),
      ),
    );
  }
}

class MyAIWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIBloc, AIState>(
      builder: (context, state) {
        if (state is AIImageRecognitionSuccess) {
          // Display recognition results
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Recognition Results:'),
              Column(
                children: state.recognitionResults!.map((result) {
                  return Text('${result['label']}: ${result['confidence']}');
                }).toList(),
              ),
            ],
          );
        } else if (state is AIError) {
          // Display error message
          return Center(child: Text('Error: ${state.message}'));
        } else {
          return Container(); // Initial state or loading state
        }
      },
    );
  }
}

class MyAIWidgetWrapper extends StatefulWidget {
  const MyAIWidgetWrapper({
    Key? key,
  }) : super(key: key);

  @override
  State<MyAIWidgetWrapper> createState() => _MyAIWidgetWrapperState();
}

class _MyAIWidgetWrapperState extends State<MyAIWidgetWrapper> {
  var imagePaths = [
     'assets/images/black.png',
    // 'assets/images/nevi.png',
    // 'assets/images/squamus_cell_carcinoma.png',
    // 'assets/images/melanoma.png',
    //'assets/images/basal_cell_carcinoma.png'//224x224
    //'assets/images/basal_cell_carcinoma.jpg'
    'assets/images/basal_cell_carcinoma_224.jpg'
  ];
  String imagePath = '';

  Widget buildImage(String imagePath) {
    return FutureBuilder<ByteData>(
        future: rootBundle.load(imagePath),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            {
              return Container(
                  width: 300.0,
                  height: 300.0,
                  decoration: new BoxDecoration(
                    image: snapshot.data == null
                        ? null
                        : new DecorationImage(
                            image: new MemoryImage(
                                snapshot.data!.buffer.asUint8List()),
                          ),
                  ));
            }
          } else {
            return Container(width: 300.0, height: 300.0);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final aiBloc = BlocProvider.of<AIBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Skin Lesion AI Detector'),
      ),
      body: Column(
        children: [
          buildImage(imagePath),
          MyAIWidget(),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                imagePath =
                    imagePaths[(new Random()).nextInt(imagePaths.length)];
              });
              aiBloc.add(PerformImageRecognitionEvent(imagePath: imagePath));
            },
            child: Text('Recognize Image'),
          )
        ],
      ),
    );
  }
}
