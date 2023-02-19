import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/all_buildings/add_user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';
import 'update_building_info.dart';

class UpdateBuilding extends StatefulWidget {
  const UpdateBuilding({Key? key, required this.buildingID, required this.buildingPhoto, required this.buildingName, required this.buildingAddress, this.guard}) : super(key: key);
  final int buildingID;
  final String buildingName, buildingAddress, buildingPhoto;
  final Map? guard;

  @override
  State<UpdateBuilding> createState() => _UpdateBuildingState();
}

class _UpdateBuildingState extends State<UpdateBuilding> {
  //Variables
  String accessToken = "";
  Map? buildingInfo;
  Map<String, dynamic> buildingExecutiveUsers = {};
  List buildingCommittee = [];
  List flatOwners = [];
  List managers = [];
  List residents = [];
  List ownedFlats = [];
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

//APIs
  Future<void> readBuildingExecutiveUserList({required String accessToken, required int buildingID}) async {
    print("................$buildingID................");
    ownedFlats.clear();
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/info/contacts/list/for-admin?buildingId=$buildingID"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => buildingExecutiveUsers = result["data"]);
        setState(() => buildingCommittee = result["data"]["committeeHeads"] + result["data"]["committeeMembers"]);
        setState(() => managers = result["data"]["manager"]);
        setState(() => flatOwners = result["data"]["flatOwners"]);
        setState(() => residents = result["data"]["residents"]);
        for (int i = 0; i < flatOwners.length; i++) {
          ownedFlats.add(flatOwners[i]["flat"]["flatName"]);
        }
        ownedFlats = ownedFlats.toSet().toList();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> updateUserPassword({required String accessToken, required String newPassword, required String confirmPassword, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/update/password/by-admin"), headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "password": newPassword, "confirmPassword": confirmPassword}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(newPassword);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Password Updated", onTap: () => routeBack(context));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> readBuildingInfo({required String accessToken, required int buildingID}) async {
    try {
      var response = await http.get(Uri.parse("$baseUrl/building/info?bid=$buildingID"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => buildingInfo = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> removeManager({required String accessToken, required int buildingID, required int managerID}) async {
    print({"managerId": managerID, "buildingId": buildingID}.toString());
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/remove/manager"), headers: authHeader(accessToken), body: jsonEncode({"managerId": managerID, "buildingId": buildingID}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        await defaultInit();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> removeCommittee({required String accessToken, required int buildingID, required int userId}) async {
    print({"memberId": userId, "buildingId": buildingID}.toString());
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/remove/committee"), headers: authHeader(accessToken), body: jsonEncode({"memberId": userId, "buildingId": buildingID}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        await defaultInit();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> removeFlatOwner({required String accessToken, required int flatId, required int userId}) async {
    print({"userId": userId, "flatId": flatId}.toString());
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/remove/flat-owner/by-user"), headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "flatId": flatId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        await defaultInit();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> removeRole({required String accessToken, required int userID, required String existingRole}) async {
    print({"uid": userID, "role": existingRole}.toString());
    try {
      var response = await http.post(Uri.parse("$baseUrl/auth/test/roles/remove-role?userId=$userID&role=$existingRole"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        await defaultInit();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> removeResident({required String accessToken, required int userId, required String role}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/remove/building/by-user"), headers: authHeader(accessToken), body: jsonEncode({"userId": userId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "This user just became homeless 😢", onTap: () => routeBack(context));
        await defaultInit();
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
    await readBuildingInfo(accessToken: accessToken, buildingID: widget.buildingID);
    await readBuildingExecutiveUserList(accessToken: accessToken, buildingID: widget.buildingID);
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
            pageName: "All Buildings",
            header: "Information: ${widget.buildingName}",
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              //region Building Info
              dataTableContainer(
                  isScrollableWidget: false,
                  paddingBottom: 0,
                  headerPadding: buildingInfo == null ? 8 : 0,
                  title: "Building Information",
                  primaryButtonText: "Edit",
                  primaryButtonOnTap: () => route(context, UpdateBuildingInfo(buildingID: widget.buildingID, buildingName: widget.buildingName, buildingNameAddress: widget.buildingAddress, buildingPhoto: widget.buildingPhoto)),
                  child: buildingInfo == null
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Information Found")))
                      : Row(children: [
                          dataTableListTile(flex: 2, title: 'Building Name: ${buildingInfo!["buildingName"]}', img: '$baseUrl/photos/${buildingInfo!["photo"]}'),
                          dataTableChip(
                              flex: 2,
                              label: buildingInfo!["approvalStatus"] == "accepted" ? "active" : buildingInfo!["approvalStatus"],
                              color: buildingInfo!["approvalStatus"] == "pending"
                                  ? const Color(0xFFE67E22)
                                  : buildingInfo!["approvalStatus"] == "rejected"
                                      ? const Color(0xFFFF2C2C)
                                      : const Color(0xFF3498DB)),
                          dataTableSingleInfo(flex: 2, title: 'Address:\n${buildingInfo!["address"]}', alignment: TextAlign.start),
                          dataTableNull()
                        ])),
              //endregion

              //region Guard
              if (widget.guard != null)
                dataTableContainer(
                    isScrollableWidget: false,
                    paddingBottom: 0,
                    title: "Guard Device Access Point",
                    headerRow: ["Name", "Role", "Action"],
                    flex: [2, 1, 1],
                    child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        primary: false,
                        itemCount: 1,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(flex: 2, title: widget.guard!["name"], subtitle: widget.guard!["email"]),
                              dataTableSingleInfo(title: "Guard Device Access Point"),
                              dataTableIcon(
                                  toolTip: "Change Password",
                                  onTap: () {
                                    setState(() => newPasswordController.clear());
                                    setState(() => confirmPasswordController.clear());
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) => updatePassword(
                                            userId: widget.guard!["userId"],
                                            context: context,
                                            onSubmit: () async {
                                              updateUserPassword(accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: widget.guard!["userId"]);
                                              Navigator.pop(context);
                                            }));
                                  },
                                  icon: Icons.lock_reset)
                            ]))),
              //endregion

              //region Manager
              dataTableContainer(
                  isScrollableWidget: false,
                  paddingBottom: 0,
                  title: "Building Manager",
                  primaryButtonText: "Add Manager",
                  primaryButtonOnTap: () => route(context, AddUser(buildingId: widget.buildingID, role: "Building_Manager", buildingName: widget.buildingName)),
                  headerRow: ["Name", "Role", "Action"],
                  flex: [2, 1, 1],
                  child: (managers.isEmpty)
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Manager Found")))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: managers.length,
                          itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                                dataTableListTile(flex: 4, title: managers[index]["name"], subtitle: managers[index]["email"], img: managers[index]["photo"] == null ? placeholderImage : '$baseUrl/photos/${managers[index]["photo"]}'),
                                dataTableSingleInfo(flex: 2, title: "Building Manager"),
                                dataTableIcon(
                                    toolTip: "Change Password",
                                    onTap: () {
                                      setState(() => newPasswordController.clear());
                                      setState(() => confirmPasswordController.clear());
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) => updatePassword(
                                              userId: managers[index]["userId"],
                                              context: context,
                                              onSubmit: () async {
                                                updateUserPassword(accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: managers[index]["userId"]);
                                                Navigator.pop(context);
                                              }));
                                    },
                                    icon: Icons.lock_reset),
                                dataTableIcon(
                                    toolTip: "Demote Manager",
                                    onTap: () {
                                      showPrompt(
                                          context: context,
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await removeManager(accessToken: accessToken, buildingID: widget.buildingID, managerID: managers[index]["userId"]);
                                          });
                                    },
                                    icon: Icons.cancel_outlined,
                                    color: Colors.redAccent)
                              ]))),
              //endregion

              //region Committee
              dataTableContainer(
                  isScrollableWidget: false,
                  paddingBottom: 0,
                  title: "Building Committee",
                  primaryButtonText: "Add Head",
                  secondaryButtonText: "Add Member",
                  primaryButtonOnTap: (buildingExecutiveUsers["committeeHeads"] == null || buildingExecutiveUsers["committeeHeads"].length == 0) ? () => route(context, AddUser(buildingId: widget.buildingID, role: "Committee_Head", buildingName: widget.buildingName)) : null,
                  secondaryButtonOnTap: () => route(context, AddUser(buildingId: widget.buildingID, role: "Committee_Member", buildingName: widget.buildingName)),
                  headerRow: ["Name", "Role", "Action"],
                  flex: [2, 1, 1],
                  child: (buildingCommittee.isEmpty)
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Committee Found")))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: buildingCommittee.length,
                          itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                                dataTableListTile(
                                    flex: 4, title: buildingCommittee[index]["member"]["name"], subtitle: buildingCommittee[index]["member"]["email"], img: buildingCommittee[index]["member"]["photo"] == null ? placeholderImage : '$baseUrl/photos/${buildingCommittee[index]["member"]["photo"]}'),
                                dataTableSingleInfo(flex: 2, title: buildingCommittee[index]["isHead"] ? "Committee Head" : "Committee Member"),
                                // dataTableChip(flex: 2, label: "Active"),
                                dataTableIcon(
                                    toolTip: "Change Password",
                                    onTap: () {
                                      setState(() => newPasswordController.clear());
                                      setState(() => confirmPasswordController.clear());
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) => updatePassword(
                                              userId: buildingCommittee[index]["member"]["userId"],
                                              context: context,
                                              onSubmit: () async {
                                                updateUserPassword(accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: buildingCommittee[index]["member"]["userId"]);
                                                Navigator.pop(context);
                                              }));
                                    },
                                    icon: Icons.lock_reset),
                                dataTableIcon(
                                    toolTip: "Demote From Committee",
                                    onTap: () {
                                      showPrompt(
                                          context: context,
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await removeCommittee(accessToken: accessToken, buildingID: widget.buildingID, userId: buildingCommittee[index]["member"]["userId"]);
                                          });
                                    },
                                    icon: Icons.cancel_outlined,
                                    color: Colors.redAccent)
                              ]))),
              //endregion

              //region Flat Owner
              dataTableContainer(
                  isScrollableWidget: false,
                  title: "Building Flat Owners",
                  primaryButtonText: "Flat Owner",
                  primaryButtonOnTap: () => route(context, AddUser(buildingId: widget.buildingID, role: "Flat_Owner", buildingName: widget.buildingName, ownedFlats: ownedFlats)),
                  headerRow: ["Name", "Role", "Action"],
                  flex: [2, 1, 1],
                  child: (flatOwners.isEmpty)
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Flat Owner Found")))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: flatOwners.length,
                          itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                                dataTableListTile(flex: 4, title: flatOwners[index]["user"]["name"], subtitle: flatOwners[index]["user"]["email"], img: flatOwners[index]["user"]["photo"] == null ? placeholderImage : '$baseUrl/photos/${flatOwners[index]["user"]["photo"]}'),
                                dataTableSingleInfo(flex: 2, title: "Flat Owner - ${flatOwners[index]["flat"]["flatName"]}"),
                                dataTableIcon(
                                    toolTip: "Change Password",
                                    onTap: () {
                                      setState(() => newPasswordController.clear());
                                      setState(() => confirmPasswordController.clear());
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) => updatePassword(
                                              userId: flatOwners[index]["user"]["userId"],
                                              context: context,
                                              onSubmit: () async {
                                                updateUserPassword(accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: flatOwners[index]["user"]["userId"]);
                                                Navigator.pop(context);
                                              }));
                                    },
                                    icon: Icons.lock_reset),
                                dataTableIcon(
                                    toolTip: "Demote Flat Owner",
                                    onTap: () {
                                      showPrompt(
                                          context: context,
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await removeFlatOwner(accessToken: accessToken, flatId: flatOwners[index]["flat"]["flatId"], userId: flatOwners[index]["user"]["userId"]);
                                          });
                                    },
                                    icon: Icons.cancel_outlined,
                                    color: Colors.redAccent)
                              ]))),
              //endregion

              //region Resident
              dataTableContainer(
                  isScrollableWidget: false,
                  title: "Building Residents",
                  headerRow: ["Name", "Role", "Action"],
                  flex: [2, 1, 1],
                  child: (residents.isEmpty)
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Resident Found")))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: residents.length,
                          itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                                dataTableListTile(flex: 4, title: residents[index]["name"], subtitle: residents[index]["email"], img: residents[index]["photo"] == null ? placeholderImage : '$baseUrl/photos/${residents[index]["photo"]}'),
                                dataTableSingleInfo(flex: 2, title: "Resident"),
                                dataTableIcon(
                                    toolTip: "Change Password",
                                    onTap: () {
                                      setState(() => newPasswordController.clear());
                                      setState(() => confirmPasswordController.clear());
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) => updatePassword(
                                              userId: residents[index]["userId"],
                                              context: context,
                                              onSubmit: () async {
                                                updateUserPassword(accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: residents[index]["userId"]);
                                                Navigator.pop(context);
                                              }));
                                    },
                                    icon: Icons.lock_reset),
                                dataTableIcon(
                                    toolTip: "Un-Assign Flat",
                                    onTap: () async {
                                      await showPrompt(
                                          context: context,
                                          onTap: () async {
                                            routeBack(context);
                                            await removeResident(accessToken: accessToken, role: "resident", userId: residents[index]["userId"]);
                                          });
                                    },
                                    icon: Icons.cancel_outlined,
                                    color: Colors.redAccent)
                              ])))
              //endregion
            ]),
            context: context));
  }

  AlertDialog updatePassword({required BuildContext context, required VoidCallback onSubmit, required int userId}) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: const Center(child: Text("Update User Password")),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [primaryTextField(labelText: "New Password", controller: newPasswordController), primaryTextField(labelText: "Confirm Password", controller: confirmPasswordController, bottomPadding: 0)]),
        actions: [primaryButton(paddingTop: 0, title: "Submit", onTap: onSubmit)]);
  }
}
