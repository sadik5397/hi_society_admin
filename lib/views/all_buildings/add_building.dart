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

class AddBuilding extends StatefulWidget {
  const AddBuilding({Key? key}) : super(key: key);

  @override
  State<AddBuilding> createState() => _AddBuildingState();
}

class _AddBuildingState extends State<AddBuilding> {
  //Variables
  String? accessToken;
  bool loadingWait = false;
  List<String> buildingFlatList = [];
  final TextEditingController buildingNameController = TextEditingController();
  final TextEditingController buildingAddressController = TextEditingController();
  final TextEditingController buildingFlatListController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  dynamic apiResult;
  FocusNode focusNode = FocusNode();
  late File _image = File("");
  String base64img = "";
  final ImagePicker _picker = ImagePicker();

//APIs
  Future<void> createBuilding({required String name, required String photo, required String address, required List<String> flats, required String accessToken, required VoidCallback successRoute}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building"), headers: authHeader(accessToken), body: jsonEncode({"name": name, "photo": photo, "address": address, "flats": flats}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
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
  }

  Future getImage() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() => _image = File(image!.path));
    var result = await FlutterImageCompress.compressWithFile(_image.absolute.path, minWidth: 800, minHeight: 800, quality: 70, rotate: 0);
    setState(() => base64img = (base64Encode(List<int>.from(result!)))); //error: The method 'readAsBytesSync' can't be unconditionally invoked because the receiver can be 'null'.
  }

  Future getWebImage() async {
    Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
    // var result = await FlutterImageCompress.compressWithList(bytesFromPicker!, minWidth: 800, minHeight: 800, quality: 70, rotate: 0); //todo:
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
            header: "Add New Building",
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              dataTableContainer(
                  title: "Add a new building to the Hi Society Database",
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
                      Row(children: [
                        Expanded(
                            flex: 3,
                            child: primaryTextField(
                                focusNode: focusNode,
                                hasSubmitButton: true,
                                controller: buildingFlatListController,
                                onFieldSubmittedAlternate: () {
                                  if (buildingFlatListController.text.isNotEmpty) {
                                    setState(() => buildingFlatList.addAll(buildingFlatListController.text.toString().replaceAll(' ', '').toUpperCase().split(",")));
                                  }
                                  buildingFlatListController.clear();
                                  focusNode.requestFocus();
                                },
                                onFieldSubmitted: (value) {
                                  if (buildingFlatListController.text.isNotEmpty) {
                                    setState(() => buildingFlatList.addAll(buildingFlatListController.text.toString().replaceAll(' ', '').toUpperCase().split(",")));
                                  }
                                  buildingFlatListController.clear();
                                  focusNode.requestFocus();
                                },
                                bottomPadding: 12,
                                labelText: "Flat Number List",
                                hintText: "Type then tap submit to add more",
                                required: buildingFlatList.isEmpty,
                                errorText: "Flat number list required",
                                textCapitalization: TextCapitalization.characters)),
                      ]),
                      if (buildingFlatList.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text(" Flat list confirmed:", textAlign: TextAlign.start)),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.start,
                              spacing: 12 / 2,
                              children: List.generate(
                                  buildingFlatList.length,
                                  (index) => Chip(
                                      backgroundColor: primaryColor.withOpacity(.2),
                                      deleteIcon: const Icon(Icons.cancel_outlined, size: 18),
                                      visualDensity: VisualDensity.compact,
                                      deleteIconColor: Colors.black87,
                                      onDeleted: () => setState(() => buildingFlatList.removeAt(index)),
                                      label: Text(buildingFlatList[index]))))),
                      //region Photo
                      const Padding(padding: EdgeInsets.only(top: 12, left: 14, bottom: 6), child: Text("Upload Building Photo")),
                      Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 16), child: photoUploaderPro(width: 400, height: 250, onTap: () async => kIsWeb ? getWebImage() : getImage(), base64img: base64img)),
                      //endregion Photo
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: primaryButton(
                              width: 200,
                              icon: Icons.done_all_rounded,
                              // loadingWait: loadingWait,
                              title: "Create Building",
                              onTap: () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                // setState(() => loadingWait = true);
                                if (_formKey.currentState!.validate()) {
                                  if (buildingFlatListController.text.isNotEmpty) {
                                    setState(() => buildingFlatList.addAll(buildingFlatListController.text.toString().replaceAll(' ', '').toUpperCase().split(",")));
                                    buildingFlatListController.clear();
                                    await Future.delayed(const Duration(milliseconds: 500));
                                  }
                                  await createBuilding(
                                      accessToken: accessToken!,
                                      flats: buildingFlatList,
                                      name: buildingNameController.text,
                                      address: buildingAddressController.text,
                                      photo: (base64img == "") ? "" : "data:image/png;base64,$base64img",
                                      successRoute: () => showSuccess(context: context, label: "${buildingNameController.text} Added Successfully", onTap: () => route(context, const AllBuildings())));
                                } else {
                                  showSnackBar(context: context, label: "Invalid Entry! Please Check");
                                }
                                // setState(() => loadingWait = false);
                              }))
                    ]),
                  ))
            ])));
  }
}
