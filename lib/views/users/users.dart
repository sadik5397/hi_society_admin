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
  bool selectAll = false;
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
      var response = await http.post(Uri.parse("$baseUrl/building/list/user/with-building?limit=500"), headers: authHeader(accessToken));
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
        : searchResults = (userList.where((data) => (data["name"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["phone"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["buildingName"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["buildingAddress"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["role"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["email"].toString().toLowerCase().contains(enteredKeyword.toLowerCase())))).toList();
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
                selectAllFunction: Row(children: [
                  Checkbox(
                      value: selectAll,
                      onChanged: (value) {
                        setState(() => selectableUsers = List.generate(foundUsers.length, (index) => !selectAll));
                        if (selectAll) {
                          setState(() => selectedUsers.clear());
                        } else {
                          for (int i = 0; i < foundUsers.length; i++) {
                            setState(() => selectedUsers.add(foundUsers[i]["userId"]));
                          }
                        }
                        setState(() => selectAll = value ?? false);
                      }),
                  const SelectableText("All", textAlign: TextAlign.start, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
                ]),
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
                // primaryButtonOnTap: ()=> print(selectedUsers.toString()),
                primaryButtonText: "Announcement",
                // primaryButtonText: selectableUsers.length.toString(),
                entryCount: foundUsers.length,
                headerRow: ["Select", "Name", "Role", "Building", "Action"],
                flex: [1, 4, 2, 4, 2],
                title: "All Users",
                searchWidget: primaryTextField(
                    fillColor: primaryColor.withOpacity(.1),
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
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(onTap: () async => await showDialog(context: context, builder: (BuildContext context) => moreUserOptions(userData: foundUsers[index], context: context)), index: index, children: [
                              dataTableCheckBox(
                                  value: selectableUsers[index],
                                  onChanged: (value) {
                                    setState(() => selectableUsers[index] = value);
                                    if (kDebugMode) print('${foundUsers[index]["userId"]} = ${selectableUsers[index]}');
                                    selectableUsers[index] ? selectedUsers.add(foundUsers[index]["userId"]) : selectedUsers.remove(foundUsers[index]["userId"]);
                                  }),
                              dataTableListTile(flex: 4, img: foundUsers[index]["photo"] == null ? placeholderImage : '$baseUrl/photos/${foundUsers[index]["photo"]}', title: foundUsers[index]["name"].toString(), subtitle: foundUsers[index]["email"].toString()),
                              dataTableSingleInfo(
                                  flex: 2,
                                  title: 'Role: ${foundUsers[index]["role"] == null ? "Not Available" : foundUsers[index]["role"] == "homeless" ? "Not Assigned" : capitalizeAllWord(foundUsers[index]["role"].toString().replaceAll("_", " "))}'),
                              foundUsers[index]["buildingName"] != null
                                  ? dataTableListTile(flex: 4, title: foundUsers[index]["buildingName"].toString(), subtitle: foundUsers[index]["buildingAddress"].toString(), img: foundUsers[index]["buildingPhoto"] == null ? placeholderImage : '$baseUrl/photos/${foundUsers[index]["buildingPhoto"]}')
                                  : dataTableNull(flex: 4),
                              dataTableIcon(flex: 2, toolTip: "More Options", onTap: () async => await showDialog(context: context, builder: (BuildContext context) => moreUserOptions(userData: foundUsers[index], context: context)), icon: Icons.read_more)
                            ])))));
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

  AlertDialog createNotification({required BuildContext context, required VoidCallback onSubmit}) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: const Center(child: Text("Send Instant Push Notification")),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
        buttonPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [primaryTextField(labelText: "Notification Title", controller: notificationTitle), primaryTextField(labelText: "Notification Body Text", controller: notificationBody, bottomPadding: 0)]),
        actions: [primaryButton(paddingTop: 0, title: "Send Now", onTap: onSubmit)]);
  }

  AlertDialog moreUserOptions({required BuildContext context, required Map userData}) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: (Text(capitalizeAllWord(userData["name"].toString())))),
        insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 400),
        buttonPadding: EdgeInsets.zero,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(flex: 2, child: Image.network(userData["photo"] == null ? placeholderImage : '$baseUrl/photos/${userData["photo"]}')),
            const SizedBox(width: 12),
            Expanded(
                flex: 3,
                child: DataTable(columns: [
                  DataColumn(label: Text("Key", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor))),
                  DataColumn(label: Text("Value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)))
                ], rows: [
                  DataRow(cells: [const DataCell(Text("User ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), DataCell(SelectableText(userData["userId"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))]),
                  DataRow(cells: [const DataCell(Text("Profile Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), DataCell(SelectableText(userData["name"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))]),
                  DataRow(cells: [
                    const DataCell(Text("Mobile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    DataCell(SelectableText((userData["phone"] == "00000000000" || userData["phone"] == "000000000" || userData["phone"] == "___________") ? "N/A" : userData["phone"], style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                  ]),
                  DataRow(cells: [const DataCell(Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), DataCell(SelectableText(userData["email"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))]),
                  DataRow(cells: [const DataCell(Text("Registered", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), DataCell(SelectableText(userData["createdAt"].toString().split("T")[0], style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))]),
                  DataRow(cells: [
                    const DataCell(Text("Building", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    DataCell(SelectableText(userData["buildingName"] != null ? userData["buildingName"].toString() : "N/A", style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    DataCell(SelectableText(userData["buildingName"] != null ? userData["buildingAddress"].toString() : "N/A", style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    DataCell(SelectableText(
                        userData["role"] == null
                            ? "Not Available"
                            : userData["role"] == "homeless"
                                ? "Not Assigned"
                                : capitalizeAllWord(userData["role"].toString().replaceAll("_", " ")),
                        style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                  ]),
                  DataRow(cells: [const DataCell(Text("Flat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), DataCell(SelectableText(userData["flatName"] == null ? "N/A" : userData["flatName"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))])
                ]))
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: primaryButton(
                    width: 200,
                    paddingRight: 6,
                    title: "Push Notification",
                    onTap: () {
                      setState(() => notificationTitle.clear());
                      setState(() => notificationBody.clear());
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => createNotification(
                              context: context,
                              onSubmit: () async {
                                sendNotification(accessToken: accessToken, title: notificationTitle.text, body: notificationBody.text, userId: userData["userId"]);
                                Navigator.pop(context);
                              }));
                    })),
            Expanded(
                child: primaryButton(
                    width: 200,
                    paddingRight: 6,
                    paddingLeft: 6,
                    title: "Change Password",
                    onTap: () {
                      setState(() => newPasswordController.clear());
                      setState(() => confirmPasswordController.clear());
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => updatePassword(
                              userId: userData["userId"],
                              context: context,
                              onSubmit: () async {
                                updateUserPassword(accessToken: accessToken, confirmPassword: confirmPasswordController.text, newPassword: newPasswordController.text, userId: userData["userId"]);
                                Navigator.pop(context);
                              }));
                    })),
            Expanded(
                child: primaryButton(
                    width: 200,
                    paddingLeft: 6,
                    title: "Un-assign Building",
                    onTap: () async {
                      if (userData["role"] != "homeless") {
                        await showPrompt(
                            context: context,
                            onTap: () async {
                              routeBack(context);
                              await unAssignBuilding(accessToken: accessToken, role: userData["role"].toString(), userId: userData["role"]["userId"]);
                            });
                      }
                    }))
          ])
        ]));
  }
}
