import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';
import 'add_building.dart';
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
  List foundBuildings = [];
  dynamic guardAccess = {};
  bool isVerified = true;
  TextEditingController searchController = TextEditingController();
  final Debouncer onSearchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

//APIs
  Future<void> verifyMyself({required String accessToken, required VoidCallback ifError}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/me"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
      } else {
        setState(() => isVerified = false);
        ifError.call();
        showError(context: context, label: "Please Login Again", seconds: 10);
        final pref = await SharedPreferences.getInstance();
        pref.clear();
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> readAllBuilding({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/list/with-status"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => apiResult = result["data"].reversed.toList());
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
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
        if (kDebugMode) print("Guard Device Access Created");
        var response2 = await http.post(Uri.parse("$baseUrl/building/info/status/update"), headers: authHeader(accessToken), body: jsonEncode({"buildingId": buildingID, "status": "accepted"}));
        Map result2 = jsonDecode(response2.body);
        if (kDebugMode) print(result2);
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
      showError(context: context, label: e.toString());
    }
  }

  Future<void> rejectBuilding({required String accessToken, required int buildingID, required VoidCallback onSuccess}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/info/status/update"), headers: authHeader(accessToken), body: jsonEncode({"buildingId": buildingID, "status": "rejected"}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        onSuccess.call();
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
    await verifyMyself(accessToken: accessToken, ifError: () => route(context, const SignIn()));
    if (isVerified) await readAllBuilding(accessToken: accessToken);
    if (isVerified) foundBuildings = apiResult;
  }

  void runSearch(String enteredKeyword) {
    List searchResults = [];
    enteredKeyword.isEmpty
        ? searchResults = apiResult
        : searchResults =
            (apiResult.where((data) => (data["buildingName"].toLowerCase().contains(enteredKeyword.toLowerCase()) || data["address"].toLowerCase().contains(enteredKeyword.toLowerCase())))).toList();
    setState(() => foundBuildings = searchResults);
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
                headerRow: ["Building Name", "Status", "Unique ID", "Total Flats", "Actions"],
                flex: [6, 2, 2, 2, 2],
                entryCount: foundBuildings.length,
                primaryButtonOnTap: () => route(context, const AddBuilding()),
                searchWidget: primaryTextField(
                    bottomPadding: 0,
                    labelText: "Search Building",
                    icon: Icons.search_rounded,
                    controller: searchController,
                    width: 250,
                    hasSubmitButton: true,
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: (value) => onSearchDebouncer.debounce(() => runSearch(value)),
                    onFieldSubmittedAlternate: () => runSearch(searchController.text)),
                child: foundBuildings.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: foundBuildings.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(
                                  flex: 6,
                                  title: foundBuildings[index]["buildingName"],
                                  subtitle: 'Address: ${foundBuildings[index]["address"]}',
                                  img: foundBuildings[index]["photo"] != null ? '$baseUrl/photos/${foundBuildings[index]["photo"]}' : null),
                              dataTableChip(
                                  flex: 2,
                                  label: foundBuildings[index]["approvalStatus"] == "accepted" ? "active" : foundBuildings[index]["approvalStatus"],
                                  color: foundBuildings[index]["approvalStatus"] == "pending"
                                      ? const Color(0xFFE67E22)
                                      : foundBuildings[index]["approvalStatus"] == "rejected"
                                          ? const Color(0xFFFF2C2C)
                                          : const Color(0xFF3498DB)),
                              dataTableSingleInfo(flex: 2, title: foundBuildings[index]["uniqueId"]),
                              dataTableSingleInfo(flex: 2, title: foundBuildings[index]["flats"].length.toString()),
                              foundBuildings[index]["createdBy"] != null
                                  ? dataTableIcon(
                                      onTap: () => showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return viewContactInformation(
                                                isPending: foundBuildings[index]["approvalStatus"] == "pending",
                                                context: context,
                                                contactInformation: foundBuildings[index]["createdBy"],
                                                onActive: () async => await activateBuildingAndCreateGuardDeviceAccess(
                                                    accessToken: accessToken,
                                                    buildingID: foundBuildings[index]["buildingId"],
                                                    onSuccess: () async {
                                                      routeBack(context);
                                                      // await defaultInit();
                                                      await showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) => viewGuardCredentials(
                                                              buildingName: foundBuildings[index]["buildingName"], context: context, password: guardAccess["password"], email: guardAccess["email"]));
                                                    }),
                                                onReject: () async => await rejectBuilding(
                                                    accessToken: accessToken,
                                                    buildingID: foundBuildings[index]["buildingId"],
                                                    onSuccess: () async {
                                                      routeBack(context);
                                                      await defaultInit();
                                                    }));
                                          }),
                                      toolTip: "Contact",
                                      icon: Icons.call_rounded)
                                  : dataTableNull(),
                              dataTableIcon(
                                  onTap: () => route(
                                      context,
                                      UpdateBuilding(
                                          buildingName: foundBuildings[index]["buildingName"],
                                          buildingAddress: foundBuildings[index]["address"],
                                          buildingID: foundBuildings[index]["buildingId"],
                                          buildingPhoto: foundBuildings[index]["photo"] != null ? '$baseUrl/photos/${foundBuildings[index]["photo"]}' : "",
                                          guard: foundBuildings[index]["guard"])),
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
          SelectableText(contactInformation["phone"] == "00000000000" ? "No Phone Number" : contactInformation["phone"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36, color: primaryColor)),
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
        title: const Center(child: Text("Guard Device Access Point Created", textAlign: TextAlign.center)),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 150),
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
