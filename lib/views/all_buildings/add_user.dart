import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/components.dart';
import 'package:hi_society_admin/views/all_buildings/all_buildings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';

class AddUser extends StatefulWidget {
  const AddUser({Key? key, required this.buildingId, required this.role, required this.buildingName, this.ownedFlats}) : super(key: key);
  final String role;
  final String buildingName;
  final int buildingId;
  final List? ownedFlats;

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  //variable
  String accessToken = "";
  String newRandomPassword = "";
  TextEditingController existingUserEmailController = TextEditingController();

  // List<String> roles = ["Building_Manager", "Flat_Owner", "Committee_Head", "Committee_Member"];
  List<String> flats = [];
  List<int> flatIds = [];

  // late String selectedNewUserRole = widget.role;
  String? selectedFlat;

  // late String selectedExistingUserRole = widget.role;
  bool showPassword = false;
  bool showConfirmPassword = false;
  dynamic signedUpApiResult;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  //APIs
  Future<void> assignUserToRole({required String accessToken, required String email, required String role, required VoidCallback onSuccess, int? flatId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/find/user-id/by-email?email=$email"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        int thisUserId = result["data"]["userId"];
        if (kDebugMode) print("Got user ID = $thisUserId");
        var response2 = await http.post(
            Uri.parse((role == "building_manager")
                ? "$baseUrl/building/test/manager/add?userId=$thisUserId&buildingId=${widget.buildingId}"
                : (role == "committee_head")
                    ? "$baseUrl/building/test/committee/add?userId=$thisUserId&buildingId=${widget.buildingId}&isHead=y"
                    : (role == "committee_member")
                        ? "$baseUrl/building/test/committee/add?userId=$thisUserId&buildingId=${widget.buildingId}&isHead=n"
                        : (role == "flat_owner")
                            ? "$baseUrl/building/test/flat-owner/add?userId=$thisUserId&flatId=$flatId"
                            : ""),
            headers: authHeader(accessToken));
        Map result2 = jsonDecode(response2.body);
        if (kDebugMode) print(result2);
        if (result2["statusCode"] == 200 || result2["statusCode"] == 201) {
          onSuccess.call();
        } else {
          showError(context: context, label: result2["message"][0].toString().length == 1 ? result2["message"].toString() : result2["message"][0].toString());
        }
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> doSignUp({required String email, required String name, required VoidCallback onSuccess, required String phone, required String role, int? flatId}) async {
    newRandomPassword = generateRandomString(10);
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/create"),
          headers: primaryHeader, body: jsonEncode({"email": email, "password": newRandomPassword, "confirmPassword": newRandomPassword, "name": name, "gender": "prefer_not_to_say", "phone": phone}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => signedUpApiResult = result["data"]);
        int thisUserId = result["data"]["userId"];
        var response2 = await http.post(
            Uri.parse((role == "building_manager")
                ? "$baseUrl/building/test/manager/add?userId=$thisUserId&buildingId=${widget.buildingId}"
                : (role == "committee_head")
                    ? "$baseUrl/building/test/committee/add?userId=$thisUserId&buildingId=${widget.buildingId}&isHead=y"
                    : (role == "committee_member")
                        ? "$baseUrl/building/test/committee/add?userId=$thisUserId&buildingId=${widget.buildingId}&isHead=n"
                        : (role == "flat_owner")
                            ? "$baseUrl/building/test/flat-owner/add?userId=$thisUserId&flatId=$flatId"
                            : ""),
            headers: authHeader(accessToken));
        Map result2 = jsonDecode(response2.body);
        if (kDebugMode) print(result2);
        if (result2["statusCode"] == 200 || result2["statusCode"] == 201) {
          showSnackBar(context: context, label: result2["message"]);
          onSuccess.call();
        } else {
          showSnackBar(context: context, label: result2["message"][0].toString().length == 1 ? result2["message"].toString() : result2["message"][0].toString());
        }
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> getFlatList() async {
    try {
      var response = await http.get(Uri.parse("$baseUrl/building/list/flats?bid=${widget.buildingId}"), headers: primaryHeader);
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        for (int i = 0; i < result["data"].length; i++) {
          setState(() {
            flats.add(result["data"][i]["flatName"]);
            flatIds.add(result["data"][i]["flatId"]);
          });
        }
        if (widget.ownedFlats != null) {
          for (int i = 0; i < widget.ownedFlats!.length; i++) {
            int ind = flats.indexOf(widget.ownedFlats![i]);
            setState(() {
              flats.removeAt(ind);
              flatIds.removeAt(ind);
            });
          }
        }
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
    if (widget.role == "Flat_Owner") await getFlatList();
  }

  String generateRandomString(int len) {
    var r = Random();
    const characters = '1234567890';
    return List.generate(len, (index) => characters[r.nextInt(characters.length)]).join();
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
            pageName: "all buildings",
            context: context,
            header: "Create/Assign User to ${widget.buildingName}",
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              dataTableContainer(
                  headerPadding: 8,
                  paddingBottom: 0,
                  title: "Assign an Existing Registered User",
                  isScrollableWidget: false,
                  child: Row(children: [
                    Expanded(
                        flex: 1,
                        child: primaryDropdown(
                            title: "Role",
                            options: [capitalizeAllWord(widget.role.toString().replaceAll("_", " ").toString())],
                            value: capitalizeAllWord(widget.role.toString().replaceAll("_", " ").toString()),
                            onChanged: (value) => showSnackBar(context: context, label: "Here, you shouldn't change the value of dropdown", seconds: 6))),
                    if (widget.role == "Flat_Owner")
                      Expanded(flex: 1, child: primaryDropdown(title: "Flat", options: flats, value: selectedFlat, onChanged: (value) => setState(() => selectedFlat = value.toString()))),
                    Expanded(flex: 2, child: primaryTextField(labelText: "User Email Address", controller: existingUserEmailController)),
                    Expanded(
                        flex: 1,
                        child: primaryButton(
                            paddingBottom: 24,
                            paddingTop: 4,
                            title: "Confirm",
                            onTap: () async {
                              if (widget.role == "Flat_Owner" && selectedFlat == null) showError(context: context, label: "Select a flat");
                              await assignUserToRole(
                                  flatId: widget.role == "Flat_Owner" ? flatIds[flats.indexOf(selectedFlat!)] : 0,
                                  accessToken: accessToken,
                                  email: existingUserEmailController.text,
                                  role: widget.role.toLowerCase(),
                                  onSuccess: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return viewInformationAfterAssign(
                                            context: context,
                                            onSubmit: () async => route(context, const AllBuildings()),
                                            email: existingUserEmailController.text,
                                            role: capitalizeAllWord(widget.role.replaceAll("_", " ")));
                                      }));
                            }))
                  ])),
              dataTableContainer(
                  headerPadding: 8,
                  paddingBottom: 0,
                  title: "Or, Create & Assign a Completely New User",
                  isScrollableWidget: false,
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          flex: 2,
                          child: primaryDropdown(
                              title: "Role",
                              options: [capitalizeAllWord(widget.role.toString().replaceAll("_", " ").toString())],
                              value: capitalizeAllWord(widget.role.toString().replaceAll("_", " ").toString()),
                              onChanged: (value) => showSnackBar(context: context, label: "Here, you shouldn't change the value of dropdown", seconds: 6))),
                      if (widget.role == "Flat_Owner")
                        Expanded(flex: 2, child: primaryDropdown(title: "Flat", options: flats, value: selectedFlat, onChanged: (value) => setState(() => selectedFlat = value.toString()))),
                      Expanded(flex: 6, child: primaryTextField(controller: nameController, labelText: "Full Name", keyboardType: TextInputType.name, required: true, errorText: "Name required"))
                    ]),
                    Row(children: [
                      Expanded(flex: 3, child: primaryTextField(labelText: "User Email Address", controller: emailController, keyboardType: TextInputType.emailAddress)),
                      Expanded(flex: 3, child: primaryTextField(controller: phoneController, labelText: "Phone", keyboardType: TextInputType.phone, required: true, errorText: "(Optional)")),
                      Expanded(
                          flex: 2,
                          child: primaryButton(
                              paddingBottom: 24,
                              paddingTop: 4,
                              title: "Confirm",
                              onTap: () async {
                                if (widget.role == "Flat_Owner" && selectedFlat == null) showError(context: context, label: "Select a flat");
                                await doSignUp(
                                    flatId: widget.role == "Flat_Owner" ? flatIds[flats.indexOf(selectedFlat!)] : 0,
                                    email: emailController.text,
                                    name: nameController.text,
                                    onSuccess: () => showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return viewInformationAfterSignUp(
                                              password: newRandomPassword,
                                              name: nameController.text,
                                              role: capitalizeAllWord(widget.role.replaceAll("_", " ")),
                                              context: context,
                                              email: emailController.text,
                                              onSubmit: () async => route(context, const AllBuildings()));
                                        }),
                                    phone: phoneController.text,
                                    role: widget.role.toLowerCase());
                              }))
                    ])
                  ]))
            ])));
  }

  AlertDialog viewInformationAfterSignUp({required BuildContext context, required VoidCallback onSubmit, required String name, required String email, required String role, required String password}) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: Text("New $role Created", textAlign: TextAlign.center)),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SelectableText("Name"),
          SelectableText(name, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: primaryColor)),
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
          Column(children: [primaryButton(icon: Icons.done, title: "Done", onTap: onSubmit)])
        ]);
  }

  AlertDialog viewInformationAfterAssign({required BuildContext context, required VoidCallback onSubmit, required String email, required String role}) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: Text("New $role Created", textAlign: TextAlign.center)),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SelectableText("Email"),
          SelectableText(email, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: primaryColor)),
          const SizedBox(height: 6),
          const SelectableText("From"),
          SelectableText(widget.buildingName.toString(), style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: primaryColor)),
          const SizedBox(height: 6)
        ]),
        actions: [
          Column(children: [primaryButton(icon: Icons.done, title: "Done", onTap: onSubmit)])
        ]);
  }
}
