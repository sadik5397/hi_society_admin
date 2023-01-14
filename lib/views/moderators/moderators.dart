// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/moderators/add_mods.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import '../../components.dart';

class Moderators extends StatefulWidget {
  const Moderators({Key? key}) : super(key: key);

  @override
  State<Moderators> createState() => _ModeratorsState();
}

class _ModeratorsState extends State<Moderators> {
//Variables
  String accessToken = "";
  List modUserList = [];
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController notificationTitle = TextEditingController();
  TextEditingController notificationBody = TextEditingController();

//APIs
  Future<void> readUserList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/list?limit=500"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        List allUserList = result["data"].reversed.toList();
        for (int i = 0; i < allUserList.length; i++) {
          if (allUserList[i]["role"] != null && allUserList[i]["role"]["role"] == "moderator") setState(() => modUserList.add(allUserList[i]));
        }
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> updateUserPassword({required String accessToken, required String newPassword, required String confirmPassword, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/update/password/by-admin"),
          headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "password": newPassword, "confirmPassword": confirmPassword}));
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

  Future<void> unAssignMod({required String accessToken, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/auth/test/role/assign?uid=$userId&role=homeless"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "This user just became homeless 😢", onTap: () => route(context, const Moderators()));
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
    await readUserList(accessToken: accessToken);
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
            isScrollablePage: false,
            pageName: "Moderators",
            context: context,
            header: "Moderator Users",
            child: dataTableContainer(
                isScrollableWidget: true,
                entryCount: (modUserList.length),
                title: "Moderator Users",
                primaryButtonText: "Moderator",
                primaryButtonOnTap: () => route(context, const AddMods()),
                headerRow: ["Name", "Role", "Status", "Action"],
                flex: [4, 4, 3, 2],
                child: (modUserList.isEmpty)
                    ? Center(child: Padding(padding: const EdgeInsets.all(12).copyWith(top: 0), child: const Text("No Moderator Found")))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        primary: false,
                        itemCount: modUserList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(
                                  flex: 4,
                                  title: modUserList[index]["name"],
                                  subtitle: modUserList[index]["email"],
                                  img: modUserList[index]["photo"] == null ? placeholderImage : '$baseUrl/photos/${modUserList[index]["photo"]}'),
                              dataTableListTile(flex: 4, title: capitalizeAllWord(modUserList[index]["role"]["role"]), subtitle: 'Contact: ${modUserList[index]["phone"]}', hideImage: true),
                              dataTableChip(flex: 3, label: "Active"),
                              dataTableIcon(
                                  toolTip: "Change Password",
                                  onTap: () {
                                    setState(() => newPasswordController.clear());
                                    setState(() => confirmPasswordController.clear());
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) => updatePassword(
                                            userId: modUserList[index]["userId"],
                                            context: context,
                                            onSubmit: () async {
                                              updateUserPassword(
                                                  accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: modUserList[index]["userId"]);
                                              Navigator.pop(context);
                                            }));
                                  },
                                  icon: Icons.lock_reset),
                              dataTableIcon(
                                  toolTip: "Take Away Access",
                                  onTap: () async {
                                    setState(() => newPasswordController.clear());
                                    setState(() => confirmPasswordController.clear());
                                    await showPrompt(
                                        context: context,
                                        onTap: () async {
                                          routeBack(context);
                                          await unAssignMod(accessToken: accessToken, userId: modUserList[index]["userId"]);
                                        });
                                  },
                                  icon: Icons.remove_circle_outline_rounded,
                                  color: Colors.redAccent)
                            ])))));
  }

  AlertDialog updatePassword({required BuildContext context, required VoidCallback onSubmit, required int userId}) {
    return AlertDialog(
        title: const Center(child: Text("Update User Password")),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [primaryTextField(labelText: "New Password", controller: newPasswordController), primaryTextField(labelText: "Confirm Password", controller: confirmPasswordController, bottomPadding: 0)]),
        actions: [primaryButton(paddingTop: 0, title: "Submit", onTap: onSubmit)]);
  }
}
