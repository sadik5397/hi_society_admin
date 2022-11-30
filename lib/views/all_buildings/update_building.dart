import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/all_buildings/add_user.dart';
import 'package:hi_society_admin/views/all_buildings/update_building_info.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

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
  Map<String, dynamic> buildingInfo = {};
  Map<String, dynamic> buildingExecutiveUsers = {};
  List buildingCommittee = [];
  List flatOwners = [];

//APIs
  Future<void> readBuildingExecutiveUserList({required String accessToken, required int buildingID}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/info/contacts/list/for-admin?buildingId=$buildingID"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => buildingExecutiveUsers = result["data"]);
        setState(() => buildingCommittee = result["data"]["committeeHeads"] + result["data"]["committeeMembers"]);
        setState(() => flatOwners = result["data"]["flatOwners"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
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
                  headerPadding: buildingInfo == {} ? 8 : 0,
                  title: "Building Information",
                  primaryButtonText: "Edit",
                  primaryButtonOnTap: () =>
                      route(context, UpdateBuildingInfo(buildingID: widget.buildingID, buildingName: widget.buildingName, buildingNameAddress: widget.buildingAddress, buildingPhoto: widget.buildingPhoto)),
                  child: (buildingInfo == {})
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Information Found")))
                      : Row(
                          children: [
                            dataTableListTile(flex: 2, title: 'Building Name: ${buildingInfo["buildingName"]}', img: '$baseUrl/photos/${buildingInfo["photo"]}'),
                            dataTableChip(label: buildingInfo["approvalStatus"]),
                            dataTableSingleInfo(flex: 2, title: 'Address:\n${buildingInfo["address"]}', alignment: TextAlign.start),
                            dataTableNull()
                          ],
                        )),
              //endregion

              //region Guard
              if (widget.guard != null)
                dataTableContainer(
                    isScrollableWidget: false,
                    paddingBottom: 0,
                    title: "Guard Device Access Point",
                    headerRow: ["Name", "Role", "Status", "Action"],
                    flex: [2, 2, 1, 1],
                    child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        primary: false,
                        itemCount: 1,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(flex: 2, title: widget.guard!["name"], subtitle: widget.guard!["email"]),
                              dataTableSingleInfo(flex: 2, title: "Guard Device Access Point"),
                              dataTableChip(flex: 1, label: "Active"),
                              dataTableIcon(flex: 1, toolTip: "Reset Password", icon: Icons.lock_reset, onTap: () => showPrompt(context: context, label: "Reset Password: User ID ${widget.guard!["userId"]}")),
                              //todo: Need Reset Password
                            ]))),
              //endregion

              //region Manager
              dataTableContainer(
                  isScrollableWidget: false,
                  paddingBottom: 0,
                  title: "Building Manager",
                  primaryButtonText: "Add Manager",
                  primaryButtonOnTap:
                      buildingExecutiveUsers["manager"] == null ? () => route(context, AddUser(buildingId: widget.buildingID, role: "Building_Manager", buildingName: widget.buildingName)) : null,
                  headerRow: ["Name", "Role", "Status", "Action"],
                  flex: [2, 2, 1, 1],
                  child: (buildingExecutiveUsers["manager"] == null)
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Manager Found")))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: 1,
                          itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                                dataTableListTile(flex: 2, title: buildingExecutiveUsers["manager"]["name"], subtitle: buildingExecutiveUsers["manager"]["email"]),
                                dataTableSingleInfo(flex: 2, title: "Building Manager"),
                                dataTableChip(flex: 1, label: "Active"),
                                dataTableIcon(
                                    flex: 1,
                                    toolTip: "Reset Password",
                                    icon: Icons.lock_reset,
                                    onTap: () => showPrompt(context: context, label: "Reset Password: User ID ${buildingExecutiveUsers["manager"]["userId"]}")) //todo: Need Reset Password
                              ]))),
              //endregion

              //region Committee
              dataTableContainer(
                  isScrollableWidget: false,
                  paddingBottom: 0,
                  // title: buildingExecutiveUsers["committeeHeads"].toString(),
                  title: "Building Committee",
                  primaryButtonText: "Add Head",
                  secondaryButtonText: "Add Member",
                  primaryButtonOnTap: (buildingExecutiveUsers["committeeHeads"] == null || buildingExecutiveUsers["committeeHeads"].length == 0)
                      ? () => route(
                          context,
                          AddUser(
                              buildingId: widget.buildingID,
                              role: "Committee_He"
                                  "ad",
                              buildingName: widget.buildingName))
                      : null,
                  secondaryButtonOnTap: () => route(context, AddUser(buildingId: widget.buildingID, role: "Committee_Member", buildingName: widget.buildingName)),
                  headerRow: ["Name", "Role", "Status", "Action"],
                  flex: [2, 2, 1, 1],
                  child: (buildingCommittee.isEmpty)
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Committee Found")))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: buildingCommittee.length,
                          itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                                dataTableListTile(flex: 2, title: buildingCommittee[index]["member"]["name"], subtitle: buildingCommittee[index]["member"]["email"]),
                                dataTableSingleInfo(flex: 2, title: buildingCommittee[index]["isHead"] ? "Committee Head" : "Committee Member"),
                                dataTableChip(flex: 1, label: "Active"),
                                dataTableIcon(
                                    flex: 1,
                                    toolTip: "Reset Password",
                                    icon: Icons.lock_reset,
                                    onTap: () => showPrompt(context: context, label: "Reset Password: User ID ${buildingCommittee[index]['member']['userId']}")) //todo: Need Reset Password
                              ]))),
              //endregion

              //region Flat Owner
              dataTableContainer(
                  isScrollableWidget: false,
                  title: "Building Flat Owners",
                  primaryButtonText: "Flat Owner",
                  primaryButtonOnTap: () => route(context, AddUser(buildingId: widget.buildingID, role: "Flat_Owner", buildingName: widget.buildingName)),
                  headerRow: ["Name", "Role", "Status", "Action"],
                  flex: [2, 2, 1, 1],
                  child: (flatOwners.isEmpty)
                      ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Flat Owner Found")))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          primary: false,
                          itemCount: flatOwners.length,
                          itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                                dataTableListTile(flex: 2, title: flatOwners[index]["user"]["name"], subtitle: flatOwners[index]["user"]["email"]),
                                dataTableSingleInfo(flex: 2, title: "Flat Owner: F5"),
                                dataTableChip(flex: 1, label: "Active"),
                                dataTableIcon(
                                    flex: 1,
                                    toolTip: "Reset Password",
                                    icon: Icons.lock_reset,
                                    onTap: () => showPrompt(context: context, label: "Reset Password: User ID ${flatOwners[index]['user']['userId']}")) //todo: Need Reset Password
                              ]))),
              //endregion
            ]),
            context: context));
  }
}
