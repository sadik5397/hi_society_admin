// ignore_for_file: use_build_context_synchronously
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../components.dart';

class UtilityContactSubGroup extends StatefulWidget {
  const UtilityContactSubGroup({Key? key}) : super(key: key);

  @override
  State<UtilityContactSubGroup> createState() => _UtilityContactSubGroupState();
}

class _UtilityContactSubGroupState extends State<UtilityContactSubGroup> {
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
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  Future<void> addUtilityCategory({required String accessToken, required String name}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/create"), headers: authHeader(accessToken), body: jsonEncode({"name": name}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => utilityCategoryList = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  Future<void> updateUtilityCategory({required String accessToken, required String name, required int cid}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/update"), headers: authHeader(accessToken), body: jsonEncode({"name": name, "categoryId": cid}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => utilityCategoryList = result["data"]);
        Navigator.pop(context);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  Future<void> deleteUtilityCategory({required String accessToken, required int cid}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/delete?cid=$cid"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => utilityCategoryList = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
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
            pageName: "Contact Group",
            context: context,
            header: "Utility Contact Group",
            child: Column(children: [
              const SizedBox(height: 12),
              Container(
                alignment: Alignment.centerRight,
                child: primaryButton(
                    width: 200,
                    title: "Add New Category",
                    onTap: () => showDialog(
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
                        })),
              ),
              if (utilityCategoryList.isEmpty)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
              else
                ListView.builder(
                    primary: false,
                    shrinkWrap: true,
                    itemCount: utilityCategoryList.length,
                    itemBuilder: (context, index) => smartListTile(
                        context: context,
                        title: utilityCategoryList[index]["name"],
                        onDelete: () {
                          deleteUtilityCategory(accessToken: accessToken, cid: utilityCategoryList[index]["utilityContactCategoryId"]);
                          setState(() => utilityCategoryList.removeAt(index));
                        },
                        onEdit: () {
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
                        }))
            ])));
  }

  AlertDialog addNewCategory({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
      title: const Center(child: Text("Add New Utility Category")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: primaryTextField(labelText: "Utility Category", controller: categoryController),
      actions: [primaryButton(title: "Submit", onTap: onSubmit)],
    );
  }

  AlertDialog updateCategory({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
      title: const Center(child: Text("Add New Utility Category")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: primaryTextField(labelText: "Utility Category", controller: categoryController),
      actions: [primaryButton(title: "Submit", onTap: onSubmit)],
    );
  }
}
