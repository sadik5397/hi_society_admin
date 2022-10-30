import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api.dart';
import 'main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateBuildingGuardApp extends StatefulWidget {
  const CreateBuildingGuardApp({Key? key, required this.buildingID}) : super(key: key);
  final int buildingID;

  @override
  State<CreateBuildingGuardApp> createState() => _CreateBuildingGuardAppState();
}

class _CreateBuildingGuardAppState extends State<CreateBuildingGuardApp> {
  //Variables
  String accessToken = "";
  dynamic apiResult;

//APIs
  Future<void> createGuardApp({required String accessToken, required int buildingID}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/account/create/guard?bid=$buildingID"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => apiResult = result["data"]);
        //todo: if success
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
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
        appBar: primaryAppBar(context: context, title: "Create Guard App for Building ${widget.buildingID}"),
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          primaryButton(width: 400,title: "Create Guard App", onTap: () async => await createGuardApp(accessToken: accessToken, buildingID: widget.buildingID)),
          if (apiResult != null) const SizedBox(height: 36),
          if (apiResult != null) const Text("Guard App Created"),
          if (apiResult != null) const SizedBox(height: 12),
          if (apiResult != null) const Text("Email"),
          if (apiResult != null) SelectableText(apiResult["email"], textScaleFactor: 1.5),
          if (apiResult != null) const Text("Password"),
          if (apiResult != null) SelectableText(apiResult["password"], textScaleFactor: 1.5)
        ])));
  }
}
