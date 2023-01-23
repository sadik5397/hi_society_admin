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
  List foundUsers = [];
  List selectableUsers = [];
  List<int> selectedUsers = [];
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController notificationTitle = TextEditingController();
  TextEditingController notificationBody = TextEditingController();
  TextEditingController searchController = TextEditingController();
  final Debouncer onSearchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

//APIs
  Future<void> readUserList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/list?limit=500"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => userList = result["data"].reversed.toList());
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

  Future<void> sendNotification({required String accessToken, required String title, required String body, required int userId}) async {
    Map payload = {
      "notification": {"title": title, "body": body},
      "data": {"topic": "announcement"}
    };
    String base64Str = json.encode(payload);
    try {
      if (kDebugMode) print(jsonEncode({"userId": userId, "payload": base64Str}));
      var response = await http.post(Uri.parse("$baseUrl/push/send/by-user"), headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "payload": base64Str}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Notification Sent!", onTap: () => routeBack(context));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> sendNotificationToManyUsers({required String accessToken, required String title, required String body, required List<int> userIds}) async {
    Map payload = {
      "notification": {"title": title, "body": body},
      "data": {"topic": "announcement"}
    };
    String base64Str = json.encode(payload);
    try {
      if (kDebugMode) print(jsonEncode({"userIds": userIds, "payload": base64Str}));
      var response = await http.post(Uri.parse("$baseUrl/push/send/to-many-user"), headers: authHeader(accessToken), body: jsonEncode({"userIds": userIds, "payload": base64Str}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(
            context: context,
            label: "Notification Sent to ${result["data"].length} Users",
            onTap: () {
              routeBack(context);
              setState(() => selectedUsers = []);
              setState(() => selectableUsers = List.generate(selectableUsers.length, (index) => false));
            });
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> unAssignBuilding({required String accessToken, required int userId, required String role}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/remove/building/by-user"), headers: authHeader(accessToken), body: jsonEncode({"userId": userId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        if (kDebugMode) print("$role-------------------------------$userId");
        if (role == "resident_head" || role == "resident") await http.post(Uri.parse("$baseUrl/auth/test/role/assign?uid=$userId&role=homeless"));
        showSuccess(context: context, label: "This user just became homeless 😢", onTap: () => routeBack(context));
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
    setState(() => foundUsers = userList);
    List selectedUserList = List.generate(foundUsers.length, (index) => false);
    setState(() => selectableUsers = selectedUserList);
  }

  void runSearch(String enteredKeyword) {
    List searchResults = [];
    selectedUsers = [];
    enteredKeyword.isEmpty
        ? searchResults = userList
        : searchResults = (userList.where((data) => (data["name"].toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["phone"].toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["email"].toLowerCase().contains(enteredKeyword.toLowerCase())))).toList();
    setState(() => foundUsers = searchResults);
    List selectedUserList = List.generate(foundUsers.length, (index) => false);
    setState(() => selectableUsers = selectedUserList);
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
                primaryButtonOnTap: () {
                  setState(() => notificationTitle.clear());
                  setState(() => notificationBody.clear());
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => createNotification(
                          context: context,
                          onSubmit: () async {
                            sendNotificationToManyUsers(accessToken: accessToken, title: notificationTitle.text, body: notificationBody.text, userIds: selectedUsers);
                            Navigator.pop(context);
                          }));
                },
                primaryButtonText: "Announcement",
                showPlusButton: false,
                entryCount: foundUsers.length,
                headerRow: ["Select", "Name", "Status", "Contact", "Actions"],
                flex: [1, 4, 2, 4, 4, 4],
                title: "All Users",
                searchWidget: primaryTextField(
                    bottomPadding: 0,
                    labelText: "Search Anything",
                    icon: Icons.search_rounded,
                    controller: searchController,
                    width: 250,
                    hasSubmitButton: true,
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: (value) => onSearchDebouncer.debounce(() => runSearch(value)),
                    onChanged: (value) => onSearchDebouncer.debounce(() => runSearch(value)),
                    onFieldSubmittedAlternate: () => runSearch(searchController.text)),
                child: (foundUsers.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: foundUsers.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              // dataTableCheckBox(flex: 1, value: false, onChanged: (value) => print('${foundUsers[index]["userId"]} $value')),
                              dataTableCheckBox(
                                  value: selectableUsers[index],
                                  onChanged: (value) {
                                    setState(() => selectableUsers[index] = value);
                                    if (kDebugMode) print('${foundUsers[index]["userId"]} = ${selectableUsers[index]}');
                                    selectableUsers[index] ? selectedUsers.add(foundUsers[index]["userId"]) : selectedUsers.remove(foundUsers[index]["userId"]);
                                  }),
                              dataTableListTile(
                                  flex: 4,
                                  title: foundUsers[index]["name"].toString(),
                                  subtitle:
                                      'Role: ${foundUsers[index]["role"] == null ? "Not Available" : foundUsers[index]["role"]["role"] == "homeless" ? "Not Assigned" : capitalizeAllWord(foundUsers[index]["role"]["role"].toString().replaceAll("_", " "))}'),
                              dataTableChip(flex: 2, label: "Active"),
                              dataTableListTile(
                                  flex: 4,
                                  title: 'Email: ${foundUsers[index]["email"]}',
                                  subtitle: 'Phone: ${(foundUsers[index]["phone"] == "00000000000" || foundUsers[index]["phone"] == "___________") ? "" : foundUsers[index]["phone"]}',
                                  hideImage: true),
                              // dataTableListTile(flex: 4, title: 'Name: ${'null'}', subtitle: 'Address: ${'null'}', hideImage: true),
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
                                              sendNotification(accessToken: accessToken, title: notificationTitle.text, body: notificationBody.text, userId: foundUsers[index]["userId"]);
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
                                            userId: foundUsers[index]["userId"],
                                            context: context,
                                            onSubmit: () async {
                                              updateUserPassword(
                                                  accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: foundUsers[index]["userId"]);
                                              Navigator.pop(context);
                                            }));
                                  },
                                  icon: Icons.lock_reset),
                              dataTableIcon(
                                  toolTip: "Un-assign Building",
                                  onTap: () async {
                                    if (foundUsers[index]["role"]["role"] != "homeless") {
                                      await showPrompt(
                                          context: context,
                                          onTap: () async {
                                            routeBack(context);
                                            await unAssignBuilding(accessToken: accessToken, role: foundUsers[index]["role"]["role"].toString(), userId: foundUsers[index]["userId"]);
                                          });
                                    }
                                  },
                                  icon: Icons.domain_rounded,
                                  color: (foundUsers[index]["role"] == null || foundUsers[index]["role"]["role"] == "homeless") ? Colors.black12.withOpacity(.05) : Colors.redAccent)
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

  AlertDialog createNotification({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
        title: const Center(child: Text("Send Instant Push Notification")),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [primaryTextField(labelText: "Notification Title", controller: notificationTitle), primaryTextField(labelText: "Notification Body Text", controller: notificationBody, bottomPadding: 0)]),
        actions: [primaryButton(paddingTop: 0, title: "Send Now", onTap: onSubmit)]);
  }
}
