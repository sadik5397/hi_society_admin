// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class Users extends StatefulWidget {
  const Users({Key? key}) : super(key: key);

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
//Variables
  String accessToken = "";
  List userList = [];
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController notificationTitle = TextEditingController();
  TextEditingController notificationBody = TextEditingController();

//APIs
  Future<void> readUserList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/list?limit=300"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => userList = result["data"].reversed.toList());
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
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
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> sendNotification({required String accessToken, required String title, required String body, required int userId}) async {
    Map payload = {
      "notification": {
        "title": title,
        "body": body
      },
      "data": {
        "topic": "announcement"
      }
    };
    String base64Str = payload.toString();
    try {
      var response = await http.post(Uri.parse("$baseUrl/push/send/by-user"),
          headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "payload": base64Str}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Notification Sent!", onTap: () => routeBack(context));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> unAssignBuilding({required String accessToken, required int userId, required String role}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/remove/building/by-user"),
          headers: authHeader(accessToken), body: jsonEncode({"userId": userId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        print("$role-------------------------------$userId");
        if (role == "resident_head" || role == "resident") await http.post(Uri.parse("$baseUrl/auth/test/role/assign?uid=$userId&role=homeless"));
        showSuccess(context: context, label: "This user just became homeless 😢", onTap: () => routeBack(context));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
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
            pageName: "Users",
            context: context,
            header: "User Management",
            child: dataTableContainer(
                entryCount: userList.length,
                headerRow: ["Name", "Status", "Email" "Phone", "Actions"],
                flex: [4, 2, 4, 3],
                title: "All Users",
                child: (userList.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: userList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              // dataTableListTile(flex: 1, title: userList[index]["userId"].toString(), hideImage: true),
                              dataTableListTile(
                                  flex: 4,
                                  title: userList[index]["name"].toString(),
                                  subtitle: 'Role: ${userList[index]["role"] == null ? "Not Available" :userList[index]["role"]["role"] == "homeless" ? "Not Assigned" : capitalizeAllWord(userList[index]["role"]["role"].toString().replaceAll("_", " "))}'),
                              dataTableChip(flex: 2, label: "Active"),
                              dataTableListTile(
                                  flex: 4,
                                  title: 'Email: ${userList[index]["email"]}',
                                  subtitle: 'Phone: ${(userList[index]["phone"] == "00000000000" || userList[index]["phone"] == "___________") ? "" : userList[index]["phone"]}',
                                  hideImage: true),
                              // dataTableIcon(
                              //     onTap: () => showPrompt(
                              //         context: context,
                              //         onTap: () async {
                              //           routeBack(context);
                              //           await deleteAmenityCategory(accessToken: accessToken, cid: userList[index]["userId"]);
                              //           setState(() => userList.removeAt(index));
                              //         }),
                              //     icon: Icons.delete),
                              dataTableIcon(
                                  toolTip: "Send Instant Notification",
                                  onTap: () {
                                    setState(() => notificationTitle.clear());
                                    setState(() => notificationBody.clear());
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) => createNotification(
                                            context: context,
                                            onSubmit: () async {
                                              sendNotification(
                                                  accessToken: accessToken, title: notificationTitle.text, body: notificationBody.text, userId: userList[index]["userId"]);
                                              Navigator.pop(context);
                                            }));
                                  },
                                  icon: Icons.notification_add_outlined),
                          dataTableIcon(
                                  toolTip: "Change Password",
                                  onTap: () {
                                    setState(() => newPasswordController.clear());
                                    setState(() => confirmPasswordController.clear());
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) => updatePassword(
                                            userId: userList[index]["userId"],
                                            context: context,
                                            onSubmit: () async {
                                              updateUserPassword(
                                                  accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: userList[index]["userId"]);
                                              Navigator.pop(context);
                                            }));
                                  },
                                  icon: Icons.lock_reset),dataTableIcon(
                                  toolTip: "Un-assign Building",
                                  onTap: () async{
                                    await showPrompt(context: context, onTap: ()async{
                                      routeBack(context);
                                      await unAssignBuilding(accessToken: accessToken,role: userList[index]["role"]["role"].toString(), userId: userList[index]["userId"]);
                                    });
                                  },
                                  icon: Icons.block_outlined),
                            ])))));
  }

  AlertDialog updatePassword({required BuildContext context, required VoidCallback onSubmit, required int userId}) {
    return AlertDialog(
      title: const Center(child: Text("Update User Password")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          primaryTextField(labelText: "New Password", controller: newPasswordController),
          primaryTextField(labelText: "Confirm Password", controller: confirmPasswordController, bottomPadding: 0),
        ],
      ),
      actions: [primaryButton(paddingTop: 0, title: "Submit", onTap: onSubmit)],
    );
  }

  AlertDialog createNotification({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
      title: const Center(child: Text("Send Instant Push Notification")),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
      buttonPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          primaryTextField(labelText: "Notification Title", controller: notificationTitle),
          primaryTextField(labelText: "Notification Body Text", controller: notificationBody, bottomPadding: 0),
        ],
      ),
      actions: [primaryButton(paddingTop: 0, title: "Send Now", onTap: onSubmit)],
    );
  }
}
