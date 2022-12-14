import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hi_society_admin/views/all_buildings/all_buildings.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class UpdateBuildingInfo extends StatefulWidget {
  const UpdateBuildingInfo({Key? key, required this.buildingID, required this.buildingName, required this.buildingNameAddress, required this.buildingPhoto}) : super(key: key);
  final int buildingID;
  final String buildingName, buildingNameAddress, buildingPhoto;

  @override
  State<UpdateBuildingInfo> createState() => _UpdateBuildingInfoState();
}

class _UpdateBuildingInfoState extends State<UpdateBuildingInfo> {
  //Variables
  String accessToken = "";
  late String thisBuildingPhoto = widget.buildingPhoto;
  bool loadingWait = false;
  List<String> buildingFlatList = [];
  List<int> buildingFlatListId = [];
  late TextEditingController buildingNameController = TextEditingController(text: widget.buildingName);
  late TextEditingController buildingAddressController = TextEditingController(text: widget.buildingNameAddress);
  final TextEditingController buildingFlatListController = TextEditingController();
  final TextEditingController newFlatListController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  dynamic apiResult;
  List flatObject = [];
  FocusNode focusNode = FocusNode();

  late File _image = File("");
  String base64img = "";
  final ImagePicker _picker = ImagePicker();

//APIs
  Future<void> updateBuilding({required String name, required String photo, required String address, required String accessToken, required VoidCallback successRoute}) async {
    try {
      if (kDebugMode) {
        print(jsonEncode({"name": name, "photo": photo, "address": address, "buildingId": widget.buildingID}));
      }
      var response = await http.post(Uri.parse("$baseUrl/building/info/update"),
          headers: authHeader(accessToken), body: jsonEncode({"name": name, "photo": photo != "" ? photo : null, "address": address, "buildingId": widget.buildingID}));
      Map result = jsonDecode(response.body);

      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        setState(() => apiResult = result["data"]);
        successRoute.call();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> readFlats({required String accessToken}) async {
    try {
      var response = await http.get(Uri.parse("$baseUrl/building/list/flats?bid=${widget.buildingID}"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        setState(() => flatObject = result["data"]);
        for (int i = 0; i < flatObject.length; i++) {
          setState(() => buildingFlatList.add(flatObject[i]["flatName"]));
          setState(() => buildingFlatListId.add(flatObject[i]["flatId"]));
        }
        // setState(() => buildingFlatList.sort((a, b) => a.toString().compareTo(b.toString())));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> addFlat({required String flatName, required VoidCallback successRoute}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/create/flat"), headers: authHeader(accessToken), body: jsonEncode({"flatName": flatName, "buildingId": widget.buildingID}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        setState(() => apiResult = result["data"]);
        successRoute.call();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> removeFlat({required int flatId, required VoidCallback successRoute}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/remove/flat"), headers: authHeader(accessToken), body: jsonEncode({"flatId": flatId, "buildingId": widget.buildingID}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        setState(() => apiResult = result["data"]);
        successRoute.call();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
    await readFlats(accessToken: accessToken);
  }

  Future getImage() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() => _image = File(image!.path));
    var result = await FlutterImageCompress.compressWithFile(_image.absolute.path, minWidth: 800, minHeight: 800, quality: 70, rotate: 0);
    setState(() => base64img = (base64Encode(List<int>.from(result!)))); //error: The method 'readAsBytesSync' can't be unconditionally invoked because the receiver can be 'null'.
  }

  Future getWebImage() async {
    Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
    // var result = await FlutterImageCompress.compressWithList(bytesFromPicker!, minWidth: 800, minHeight: 800, quality: 70, rotate: 0); //todo: Image Compressor
    setState(() => base64img = (base64Encode(List<int>.from(bytesFromPicker!))));
  }

//Initiate
  @override
  void initState() {
    super.initState();
    defaultInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: includeDashboard(
            isScrollablePage: true,
            pageName: "all buildings",
            context: context,
            header: "Update Building Info",
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              dataTableContainer(
                  title: "${widget.buildingName} Information",
                  isScrollableWidget: false,
                  child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(flex: 1, child: primaryTextField(controller: buildingNameController, labelText: "Name of the Building", autoFocus: true, required: true, errorText: "Building name required")),
                          Expanded(
                            flex: 2,
                            child: primaryTextField(controller: buildingAddressController, labelText: "Full Address", required: true, errorText: "Building address required"),
                          )
                        ]),
                        //region Photo
                        const Padding(padding: EdgeInsets.only(top: 12, left: 14, bottom: 6), child: Text("Upload Building Photo")),
                        Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 16),
                            child: photoUploaderPro(
                                networkImage: thisBuildingPhoto,
                                width: 400,
                                height: 250,
                                onTap: () async {
                                  setState(() => thisBuildingPhoto = "");
                                  return kIsWeb ? await getWebImage() : await getImage();
                                },
                                base64img: base64img)),
                        //endregion Photo
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: primaryButton(
                                width: 200,
                                icon: Icons.done_all_rounded,
                                // loadingWait: loadingWait,
                                title: "Update Building",
                                onTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  // setState(() => loadingWait = true);
                                  if (_formKey.currentState!.validate()) {
                                    if (buildingFlatListController.text.isNotEmpty) {
                                      setState(() => buildingFlatList.addAll(buildingFlatListController.text.toString().replaceAll(' ', '').toUpperCase().split(",")));
                                      buildingFlatListController.clear();
                                      await Future.delayed(const Duration(milliseconds: 500));
                                    }
                                    await updateBuilding(
                                        accessToken: accessToken,
                                        // flats: buildingFlatList, //todo: flats are not updating
                                        name: buildingNameController.text,
                                        address: buildingAddressController.text,
                                        photo: (base64img == "") ? "" : "data:image/png;base64,$base64img",
                                        successRoute: () => showSuccess(context: context, label: "${buildingNameController.text} Updated Successfully", onTap: () => route(context, const AllBuildings())));
                                  } else {
                                    showSnackBar(context: context, label: "Invalid Entry! Please Check");
                                  }
                                  // setState(() => loadingWait = false);
                                })),
                        const SizedBox(height: 12),
                        if (buildingFlatList.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text(" Flat List Confirmed:", textAlign: TextAlign.start)),
                        if (buildingFlatList.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  spacing: 12 / 2,
                                  children: List.generate(
                                      buildingFlatList.length,
                                      (index) => Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Chip(
                                                backgroundColor: primaryColor.withOpacity(.2),
                                                deleteIcon: const Icon(Icons.cancel_outlined, size: 18),
                                                visualDensity: VisualDensity.compact,
                                                deleteIconColor: Colors.black87,
                                                onDeleted: () async => await showPrompt(
                                                    context: context,
                                                    onTap: () async {
                                                      routeBack(context);
                                                      await removeFlat(
                                                          flatId: buildingFlatListId[index],
                                                          successRoute: () async => await showSuccess(context: context, title: "Flat Removed", label: "Now un-assign all residents of this flat"));
                                                      setState(() => buildingFlatList.removeAt(index));
                                                    }),
                                                label: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2).copyWith(right: 6), child: Text(buildingFlatList[index], textScaleFactor: 1.1))),
                                          )))),
                        Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            child: Row(children: [
                              SizedBox(width: 200, child: primaryTextField(labelText: "Add New Flat", controller: newFlatListController, bottomPadding: 12, textCapitalization: TextCapitalization.characters)),
                              SizedBox(
                                  width: 150,
                                  child: primaryButton(
                                      paddingLeft: 0,
                                      title: "Add Flat",
                                      onTap: () async {
                                        if (newFlatListController.text != "") {
                                          buildingFlatList.add(newFlatListController.text);
                                          await addFlat(flatName: newFlatListController.text, successRoute: () async => await showSuccess(context: context, label: "Flat Added"));
                                          newFlatListController.clear();
                                        }
                                      }))
                            ]))
                      ])))
            ])));
  }
}
