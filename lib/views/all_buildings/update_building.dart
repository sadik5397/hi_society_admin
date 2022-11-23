import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import '../../components.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateBuilding extends StatefulWidget {
  const UpdateBuilding({Key? key, required this.buildingID, required this.buildingName, required this.guard}) : super(key: key);
  final int buildingID;
  final String buildingName;
  final Map guard;

  @override
  State<UpdateBuilding> createState() => _UpdateBuildingState();
}

class _UpdateBuildingState extends State<UpdateBuilding> {
  //Variables
  String accessToken = "";
  dynamic apiResult;

//APIs
  Future<void> createGuardAccess({required String accessToken, required int buildingID}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/account/create/guard?bid=$buildingID"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
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

  Future<void> createManagerAccount({required String accessToken, required int buildingID, required int userID}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/test/manager/add?buildingId=$buildingID&userId=$userID"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
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

  Future<void> createCommitteeAccount({required String accessToken, required int buildingID, required int userID, required String isHead}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/test/committee/add?buildingId=$buildingID&userId=$userID&isHead=$isHead"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
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

  Future<void> createFlatOwnerAccount({required String accessToken, required int flatID, required int userID}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/test/flat-owner/add?buildingId=$flatID&userId=$userID"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
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
        body: includeDashboard(
            pageName: "All Buildings",
            header: "Information: ${widget.buildingName}",
            child: dataTableContainer(title: "Prime Users", child: FlutterLogo()),
            context: context));
  }
}


// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//       body: includeDashboard(
//           pageName: "All Buildings",
//           header: "Information: ${widget.buildingName}",
//           child: Center(
//               child: Column(mainAxisSize: MainAxisSize.min, children: [
//                 SelectableText(widget.guard.toString()),
//                 (widget.guard["result"] == "null")
//                     ? primaryButton(width: 400, title: "Create Device Access", onTap: () async => await createGuardAccess(accessToken: accessToken, buildingID: widget.buildingID))
//                     : basicListTile(context: context, title: widget.guard["name"], subTitle: widget.guard["email"]),
//                 primaryButton(width: 400, title: "Create Building Manager Account", onTap: () async => await createManagerAccount(accessToken: accessToken, buildingID: widget.buildingID, userID: 16)), //todo
//                 primaryButton(
//                     width: 400,
//                     title: "Create Building Committee Head Account",
//                     onTap: () async => await createCommitteeAccount(accessToken: accessToken, buildingID: widget.buildingID, userID: 15, isHead: "y")), //todo:
//                 primaryButton(
//                     width: 400,
//                     title: "Create Building Committee Member Account",
//                     onTap: () async => await createCommitteeAccount(accessToken: accessToken, buildingID: widget.buildingID, userID: 15, isHead: "n")),
//                 primaryButton(width: 400, title: "Create Flat Owner Account", onTap: () async => await createFlatOwnerAccount(accessToken: accessToken, flatID: widget.buildingID, userID: 15)), //todo:
//                 if (apiResult != null) const SizedBox(height: 36),
//                 if (apiResult != null) const Text("Guard App Created"),
//                 if (apiResult != null) const SizedBox(height: 12),
//                 if (apiResult != null) const Text("Email"),
//                 if (apiResult != null) SelectableText(apiResult["email"], textScaleFactor: 1.5),
//                 if (apiResult != null) const Text("Password"),
//                 if (apiResult != null) SelectableText(apiResult["password"], textScaleFactor: 1.5)
//               ])),
//           context: context));
// }