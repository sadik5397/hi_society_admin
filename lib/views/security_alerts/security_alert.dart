// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

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
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> addAlertType({required String accessToken, required String name}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/security-alert/admin/alert-type/create"), headers: authHeader(accessToken), body: jsonEncode({"alertName": name}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(name);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "$name Added");
        setState(() => securityAlertTypeList = result["data"]);
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
            pageName: "Emergency Alerts",
            context: context,
            header: "Emergency Alert Management",
            child: dataTableContainer(
                title: "Category",
                entryCount: securityAlertTypeList.length,
                headerRow: ["Category Name", "Status"],
                flex: [6, 2],
                primaryButtonOnTap: () => showDialog(
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
                    }),
                child: (securityAlertTypeList.isEmpty)
                    ? const Center(child: NoData())
                    : ListView.builder(
                        itemCount: securityAlertTypeList.length,
                        itemBuilder: (context, index) =>
                            dataTableAlternativeColorCells(index: index, children: [dataTableListTile(flex: 6, title: securityAlertTypeList[index]["alertName"]), dataTableChip(flex: 2, label: "Active")])))));
  }

  AlertDialog addNewType({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: const Center(child: Text("Add New Emergency Alert Type")),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: primaryTextField(labelText: "Alert Type", controller: alertTypeController),
        actions: [primaryButton(title: "Submit", onTap: onSubmit)]);
  }
}
