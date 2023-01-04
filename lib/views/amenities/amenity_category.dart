// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class AmenityCategory extends StatefulWidget {
  const AmenityCategory({Key? key}) : super(key: key);

  @override
  State<AmenityCategory> createState() => _AmenityCategoryState();
}

class _AmenityCategoryState extends State<AmenityCategory> {
//Variables
  String accessToken = "";
  List amenityCategoryList = [];
  TextEditingController categoryController = TextEditingController();

//APIs
  Future<void> viewAmenityCategory({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/amenity-booking/list/amenity/category"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => amenityCategoryList = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> addAmenityCategory({required String accessToken, required String name}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/amenity-booking/create/amenity/category"), headers: authHeader(accessToken), body: jsonEncode({"categoryName": name}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "$name Added");
        setState(() => amenityCategoryList = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> updateAmenityCategory({required String accessToken, required String name, required int cid}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/amenity-booking/update/amenity/category"), headers: authHeader(accessToken), body: jsonEncode({"categoryName": name, "amenityCategoryId": cid}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Updated to $name");
        setState(() => amenityCategoryList = result["data"]);
        Navigator.pop(context);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> deleteAmenityCategory({required String accessToken, required int cid}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/amenity-booking/remove/amenity/category"), headers: authHeader(accessToken), body: jsonEncode({"amenityCategoryId": cid}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Amenity Deleted");
        setState(() => amenityCategoryList = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
    await viewAmenityCategory(accessToken: accessToken);
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
            pageName: "Amenities",
            context: context,
            header: "Amenity Management",
            child: dataTableContainer(
                entryCount: amenityCategoryList.length,
                headerRow: ["Category Name", "Status", "Actions"],
                flex: [4, 2, 2],
                primaryButtonOnTap: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return addNewCategory(
                          context: context,
                          onSubmit: () async {
                            addAmenityCategory(accessToken: accessToken, name: categoryController.text);
                            Navigator.pop(context);
                            setState(() {
                              amenityCategoryList.add({"categoryName": categoryController.text});
                            });
                            categoryController.clear();
                          });
                    }),
                title: "Category",
                child: (amenityCategoryList.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: amenityCategoryList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(flex: 4, title: amenityCategoryList[index]["categoryName"]),
                              dataTableChip(flex: 2, label: "Active"),
                              dataTableIcon(
                                  toolTip: "DELETE",
                                  onTap: () => showPrompt(
                                      context: context,
                                      onTap: () async {
                                        routeBack(context);
                                        await deleteAmenityCategory(accessToken: accessToken, cid: amenityCategoryList[index]["amenityCategoryId"]);
                                        setState(() => amenityCategoryList.removeAt(index));
                                      }),
                                  icon: Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                              dataTableIcon(
                                  onTap: () {
                                    setState(() => categoryController = TextEditingController(text: amenityCategoryList[index]["categoryName"]));
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) => updateCategory(
                                            context: context,
                                            onSubmit: () async {
                                              updateAmenityCategory(accessToken: accessToken, name: categoryController.text, cid: amenityCategoryList[index]["amenityCategoryId"]);
                                              Navigator.pop(context);
                                              setState(() {
                                                amenityCategoryList[index]["categoryName"] = categoryController.text;
                                              });
                                              categoryController.clear();
                                            }));
                                  },
                                  icon: Icons.edit),
                            ])))));
  }

  AlertDialog addNewCategory({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
      title: const Center(child: Text("Add New Amenity Category")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: primaryTextField(labelText: "Amenity Category", controller: categoryController),
      actions: [primaryButton(title: "Submit", onTap: onSubmit)],
    );
  }

  AlertDialog updateCategory({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
      title: const Center(child: Text("Add New Amenity Category")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: primaryTextField(labelText: "Amenity Category", controller: categoryController),
      actions: [primaryButton(title: "Submit", onTap: onSubmit)],
    );
  }
}
