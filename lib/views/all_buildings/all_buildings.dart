import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import '../../components.dart';
import 'update_building.dart';

class AllBuildings extends StatefulWidget {
  const AllBuildings({Key? key}) : super(key: key);

  @override
  State<AllBuildings> createState() => _AllBuildingsState();
}

class _AllBuildingsState extends State<AllBuildings> {
  //Variables
  String accessToken = "";
  List apiResult = [];
  dynamic guardAccess = {};

//APIs
  Future<void> verifyMyself({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/me"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        if (result["data"]["role"] != "admin") {
          // ignore: use_build_context_synchronously
          route(context, const SignIn());
          showSnackBar(context: context, label: "You're NOT ALLOWED to login as ADMIN", seconds: 10);
          final pref = await SharedPreferences.getInstance();
          pref.clear();
        }
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        if (result["data"]["role"] != "admin") {
          // ignore: use_build_context_synchronously
          route(context, const SignIn());
          showSnackBar(context: context, label: "You're NOT ALLOWED to login as ADMIN", seconds: 10);
          final pref = await SharedPreferences.getInstance();
          pref.clear();
        }
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  Future<void> readAllBuilding({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/list/with-status"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => apiResult = result["data"].reversed.toList());
        //todo: if success
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  Future<void> activateBuildingAndCreateGuardDeviceAccess({required String accessToken, required int buildingID, required VoidCallback onSuccess}) async {
    try {
      var response1 = await http.post(Uri.parse("$baseUrl/building/account/create/guard?bid=$buildingID"), headers: authHeader(accessToken));
      Map result1 = jsonDecode(response1.body);
      if (kDebugMode) print(result1);
      if (result1["statusCode"] == 200 || result1["statusCode"] == 201) {
        showSnackBar(context: context, label: result1["message"]);
        setState(() => guardAccess = result1["data"]);
        print("Guard Device Access Created");
        var response2 = await http.post(Uri.parse("$baseUrl/building/info/status/update"), headers: authHeader(accessToken), body: jsonEncode({"buildingId": buildingID, "status": "accepted"}));
        Map result2 = jsonDecode(response2.body);
        print(result2);
        if (result2["statusCode"] == 200 || result2["statusCode"] == 201) {
          showSnackBar(context: context, label: result2["message"]);
          onSuccess.call();
        } else {
          showSnackBar(context: context, label: result2["message"][0].toString().length == 1 ? result2["message"].toString() : result2["message"][0].toString());
        }
      } else {
        showSnackBar(context: context, label: result1["message"][0].toString().length == 1 ? result1["message"].toString() : result1["message"][0].toString());
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

  Future<void> rejectBuilding({required String accessToken, required int buildingID, required VoidCallback onSuccess}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/info/status/update"), headers: authHeader(accessToken), body: jsonEncode({"buildingId": buildingID, "status": "rejected"}));
      Map result = jsonDecode(response.body);
      print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        onSuccess.call();
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
    await verifyMyself(accessToken: accessToken);
    await readAllBuilding(accessToken: accessToken);
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
            context: context,
            header: "All Registered Buildings",
            child: dataTableContainer(
                title: "All Buildings",
                headerRow: ["Building Name", "Status", "Unique ID", "Total Flats", "Acton"],
                flex: [6, 2, 2, 2, 2],
                entryCount: apiResult.length,
                primaryButtonOnTap: () {},
                child: apiResult.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: apiResult.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(flex: 6, title: apiResult[index]["buildingName"], subtitle: 'Address: ${apiResult[index]["address"]}', img: apiResult[index]["photo"]),
                              dataTableChip(
                                  flex: 2,
                                  label: apiResult[index]["approvalStatus"] == "accepted" ? "active" : apiResult[index]["approvalStatus"],
                                  color: apiResult[index]["approvalStatus"] == "pending"
                                      ? const Color(0xFFE67E22)
                                      : apiResult[index]["approvalStatus"] == "rejected"
                                          ? const Color(0xFFFF2C2C)
                                          : const Color(0xFF3498DB)),
                              dataTableSingleInfo(flex: 2, title: apiResult[index]["uniqueId"]),
                              dataTableSingleInfo(flex: 2, title: apiResult[index]["flats"].length.toString()),
                              apiResult[index]["createdBy"] != null
                                  ? dataTableIcon(
                                      onTap: () => showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return viewContactInformation(
                                                isPending: apiResult[index]["approvalStatus"] == "pending",
                                                context: context,
                                                contactInformation: apiResult[index]["createdBy"],
                                                onActive: () async => await activateBuildingAndCreateGuardDeviceAccess(
                                                    accessToken: accessToken,
                                                    buildingID: apiResult[index]["buildingId"],
                                                    onSuccess: () async {
                                                      routeBack(context);
                                                      await defaultInit();
                                                      showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) => viewGuardCredentials(
                                                              buildingName: apiResult[index]["buildingName"], context: context, password: guardAccess["password"], email: guardAccess["email"]));
                                                    }),
                                                onReject: () async => await rejectBuilding(
                                                    accessToken: accessToken,
                                                    buildingID: apiResult[index]["buildingId"],
                                                    onSuccess: () async {
                                                      routeBack(context);
                                                      await defaultInit();
                                                    }));
                                          }),
                                      toolTip: "Contact",
                                      icon: Icons.call_rounded)
                                  : dataTableNull(),
                              dataTableIcon(
                                  onTap: () => route(context, UpdateBuilding(buildingName: apiResult[index]["buildingName"], buildingID: apiResult[index]["buildingId"], guard: apiResult[index]["guard"])),
                                  icon: Icons.edit),
                            ])))));
  }

  AlertDialog viewContactInformation({required bool isPending, required BuildContext context, required VoidCallback onActive, required VoidCallback onReject, required Map contactInformation}) {
    return AlertDialog(
        title: const Center(child: Text("Contact Information")),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SelectableText("Name"),
          SelectableText(contactInformation["name"], style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: primaryColor)),
          const SizedBox(height: 6),
          const SelectableText("Phone"),
          SelectableText(contactInformation["phone"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36, color: primaryColor)),
          const SelectableText("Email"),
          SelectableText(contactInformation["email"], style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: primaryColor)),
          const SizedBox(height: 6)
        ]),
        actions: [
          Column(children: [
            if (isPending) primaryButton(icon: Icons.close_fullscreen_rounded, primary: false, paddingBottom: 6, title: "Keep it pending", onTap: () => routeBack(context)),
            if (isPending) primaryButton(icon: Icons.close, primary: false, paddingBottom: 6, title: "Reject", onTap: onReject),
            if (isPending) primaryButton(icon: Icons.done, title: "Activate This Building", onTap: onActive),
            if (!isPending) primaryButton(icon: Icons.done, title: "Close", onTap: () => routeBack(context)),
          ])
        ]);
  }

  AlertDialog viewGuardCredentials({required String buildingName, required BuildContext context, required String password, required String email}) {
    return AlertDialog(
        title: const Center(child: Text("Guard Device Access Created", textAlign: TextAlign.center)),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SelectableText("Building Name"),
          SelectableText(buildingName, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: primaryColor)),
          const SizedBox(height: 6),
          const SelectableText("Password"),
          SelectableText(password, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36, color: primaryColor)),
          const Text("Please save/write down this password somewhere else.\nYou will not find it again once you click DONE.", textAlign: TextAlign.center, textScaleFactor: .8),
          const SizedBox(height: 8),
          const SelectableText("Email"),
          SelectableText(email, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: primaryColor)),
          const SizedBox(height: 6)
        ]),
        actions: [
          Column(children: [primaryButton(icon: Icons.done, title: "Done", onTap: () => routeBack(context))])
        ]);
  }
}
