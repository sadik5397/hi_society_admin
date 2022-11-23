// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../components.dart';

class SecurityAlertGroup extends StatefulWidget {
  const SecurityAlertGroup({Key? key}) : super(key: key);

  @override
  State<SecurityAlertGroup> createState() => _SecurityAlertGroupState();
}

class _SecurityAlertGroupState extends State<SecurityAlertGroup> {
//Variables
  String accessToken = "";
  List securityAlertTypeList = [];
  TextEditingController alertTypeController = TextEditingController();

//APIs
  Future<void> viewAlertType({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/security-alert/alert-type/list"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => securityAlertTypeList = result["data"]);
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  Future<void> addAlertType({required String accessToken, required String name}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/security-alert/admin/alert-type/create"), headers: authHeader(accessToken), body: jsonEncode({"alertName": name}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => securityAlertTypeList = result["data"]);
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  // Future<void> updateUtilityCategory({required String accessToken, required String name, required int cid}) async {
  //   try {
  //     var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/update"), headers: authHeader(accessToken), body: jsonEncode({"name": name, "categoryId": cid}));
  //     Map result = jsonDecode(response.body);
  //     print(name);
  //     print(result);
  //     if (result["statusCode"] == 200 || result["statusCode"] == 201) {
  //       showSnackBar(context: context, label: result["message"]);
  //       setState(() => securityAlertTypeList = result["data"]);
  //       Navigator.pop(context);
  //     } else {
  //       showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
  //       //todo: if error
  //     }
  //   } on Exception catch (e) {
  //     showSnackBar(context: context, label: e.toString());
  //   }
  // }
  //
  // Future<void> deleteUtilityCategory({required String accessToken, required int cid}) async {
  //   try {
  //     var response = await http.post(Uri.parse("$baseUrl/utility-contact/manage/category/delete?cid=$cid"), headers: authHeader(accessToken));
  //     Map result = jsonDecode(response.body);
  //     print(result);
  //     if (result["statusCode"] == 200 || result["statusCode"] == 201) {
  //       showSnackBar(context: context, label: result["message"]);
  //       setState(() => securityAlertTypeList = result["data"]);
  //     } else {
  //       showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
  //       //todo: if error
  //     }
  //   } on Exception catch (e) {
  //     showSnackBar(context: context, label: e.toString());
  //   }
  // }

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
    await viewAlertType(accessToken: accessToken);
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
      pageName: "Security Alerts",
      context: context,
      header: "Security Alert Type",
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          alignment: Alignment.centerRight,
          child: primaryButton(
              width: 200,
              title: "Add New Type",
              onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return addNewType(
                        context: context,
                        onSubmit: () async {
                          addAlertType(accessToken: accessToken, name: alertTypeController.text);
                          Navigator.pop(context);
                          setState(() {
                            securityAlertTypeList.add({"alertName": alertTypeController.text});
                          });
                          alertTypeController.clear();
                        });
                  })),
        ),
        if (securityAlertTypeList.isEmpty)
          const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
        else
          ListView.builder(
              primary: false,
              shrinkWrap: true,
              itemCount: securityAlertTypeList.length,
              itemBuilder: (context, index) => smartListTile(
                    context: context,
                    title: securityAlertTypeList[index]["alertName"],
                    onDelete: () => showSnackBar(context: context, label: "This item can't be deleted"),
                    onEdit: () => showSnackBar(context: context, label: "This item can't be edited"),
                    // onDelete: () {
                    //   deleteUtilityCategory(accessToken: accessToken, cid: securityAlertTypeList[index]["utilityContactCategoryId"]);
                    //   setState(() => securityAlertTypeList.removeAt(index));
                    // },
                    // onEdit: () {
                    //   setState(() => alertTypeController = TextEditingController(text: securityAlertTypeList[index]["name"]));
                    //   showDialog(
                    //       context: context,
                    //       builder: (BuildContext context) => updateCategory(
                    //           context: context,
                    //           onSubmit: () async {
                    //             updateUtilityCategory(accessToken: accessToken, name: alertTypeController.text, cid: securityAlertTypeList[index]["utilityContactCategoryId"]);
                    //             Navigator.pop(context);
                    //             setState(() {
                    //               securityAlertTypeList[index]["name"] = alertTypeController.text;
                    //             });
                    //             alertTypeController.clear();
                    //           }));
                    // }
                  ))
      ]),
    ));
  }

  AlertDialog addNewType({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
      title: const Center(child: Text("Add New Security Alert Type")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: primaryTextField(labelText: "Alert Type", controller: alertTypeController),
      actions: [primaryButton(title: "Submit", onTap: onSubmit)],
    );
  }

// AlertDialog updateCategory({required BuildContext context, required VoidCallback onSubmit}) {
//   return AlertDialog(
//     title: const Center(child: Text("Add New Utility Category")),
//     insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
//     buttonPadding: EdgeInsets.zero,
//     content: primaryTextField(labelText: "Utility Category", controller: alertTypeController),
//     actions: [primaryButton(title: "Submit", onTap: onSubmit)],
//   );
// }
}
