// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class UtilityContactCategory extends StatefulWidget {
  const UtilityContactCategory({Key? key}) : super(key: key);

  @override
  State<UtilityContactCategory> createState() => _UtilityContactCategoryState();
}

class _UtilityContactCategoryState extends State<UtilityContactCategory> {
//Variables
  String accessToken = "";
  List utilityCategoryList = [];
  TextEditingController categoryController = TextEditingController();

//APIs
  Future<void> viewUtilityCategory({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/utility-contact/view/category"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => utilityCategoryList = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> addUtilityCategory({required String accessToken, required String name}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/create"), headers: authHeader(accessToken), body: jsonEncode({"name": name}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "$name Added");
        setState(() => utilityCategoryList = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> updateUtilityCategory({required String accessToken, required String name, required int cid}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/update"), headers: authHeader(accessToken), body: jsonEncode({"name": name, "categoryId": cid}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Updated to $name");
        setState(() => utilityCategoryList = result["data"]);
        Navigator.pop(context);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> deleteUtilityCategory({required String accessToken, required int cid}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/delete?cid=$cid"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Category Deleted");
        setState(() => utilityCategoryList = result["data"]);
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
    await viewUtilityCategory(accessToken: accessToken);
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
            pageName: "Utility Contacts",
            context: context,
            header: "Utility Contact Management",
            child: dataTableContainer(
                entryCount: utilityCategoryList.length,
                headerRow: ["Category Name", "Status", "Actions"],
                flex: [4, 2, 2],
                primaryButtonOnTap: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return addNewCategory(
                          context: context,
                          onSubmit: () async {
                            addUtilityCategory(accessToken: accessToken, name: categoryController.text);
                            Navigator.pop(context);
                            setState(() {
                              utilityCategoryList.add({"name": categoryController.text});
                            });
                            categoryController.clear();
                          });
                    }),
                title: "Category",
                child: (utilityCategoryList.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: utilityCategoryList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(flex: 4, title: utilityCategoryList[index]["name"]),
                              dataTableChip(flex: 2, label: "Active"),
                              dataTableIcon(
                                  toolTip: "Delete",
                                  onTap: () => showPrompt(
                                      context: context,
                                      onTap: () async {
                                        routeBack(context);
                                        await deleteUtilityCategory(accessToken: accessToken, cid: utilityCategoryList[index]["utilityContactCategoryId"]);
                                        setState(() => utilityCategoryList.removeAt(index));
                                      }),
                                  icon: Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                              dataTableIcon(
                                  onTap: () {
                                    setState(() => categoryController = TextEditingController(text: utilityCategoryList[index]["name"]));
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) => updateCategory(
                                            context: context,
                                            onSubmit: () async {
                                              updateUtilityCategory(accessToken: accessToken, name: categoryController.text, cid: utilityCategoryList[index]["utilityContactCategoryId"]);
                                              Navigator.pop(context);
                                              setState(() {
                                                utilityCategoryList[index]["name"] = categoryController.text;
                                              });
                                              categoryController.clear();
                                            }));
                                  },
                                  icon: Icons.edit),
                            ])))));
  }

  AlertDialog addNewCategory({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(backgroundColor: Colors.white,
      title: const Center(child: Text("Add New Utility Category")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: primaryTextField(labelText: "Utility Category", controller: categoryController),
      actions: [primaryButton(title: "Submit", onTap: onSubmit)],
    );
  }

  AlertDialog updateCategory({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(backgroundColor: Colors.white,
      title: const Center(child: Text("Add New Utility Category")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: primaryTextField(labelText: "Utility Category", controller: categoryController),
      actions: [primaryButton(title: "Submit", onTap: onSubmit)],
    );
  }
}
