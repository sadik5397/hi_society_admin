import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/all_buildings/all_buildings.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController buildingHeaderPhotoController = TextEditingController();
  final TextEditingController buildingAddressController = TextEditingController();
  final TextEditingController buildingFlatListController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  dynamic apiResult;
  FocusNode focusNode = FocusNode();

//APIs
  Future<void> createBuilding({required String name, required String photo, required String address, required List<String> flats, required String accessToken, required VoidCallback successRoute}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building"), headers: authHeader(accessToken), body: jsonEncode({"name": name, "photo": photo, "address": address, "flats": flats}));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        setState(() => apiResult = result["data"]);
        successRoute.call();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
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
                                      photo: buildingHeaderPhotoController.text,
                                      successRoute: showSuccess(context: context, label: "${buildingNameController.text} Added Successfully", onTap: () => route(context, const AllBuildings())));
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
