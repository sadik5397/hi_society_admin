import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/components.dart';
import 'package:hi_society_admin/views/moderators/moderators.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';

class AddMods extends StatefulWidget {
  const AddMods({Key? key}) : super(key: key);

  @override
  State<AddMods> createState() => _AddModsState();
}

class _AddModsState extends State<AddMods> {
  //variable
  String accessToken = "";
  String newRandomPassword = "";
  TextEditingController existingUserEmailController = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  dynamic signedUpApiResult;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  //APIs
  Future<void> assignUserToRole({required String accessToken, required String email, required VoidCallback onSuccess}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/find/user-id/by-email?email=$email"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        int thisUserId = result["data"]["userId"];
        if (kDebugMode) print("Got user ID = $thisUserId");
        var response2 = await http.post(Uri.parse("$baseUrl/auth/test/role/assign?uid=$thisUserId&role=moderator"), headers: authHeader(accessToken));
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

  Future<void> doSignUp({required String email, required String name, required VoidCallback onSuccess, required String phone}) async {
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
        var response2 = await http.post(Uri.parse("$baseUrl/auth/test/role/assign?uid=$thisUserId&role=moderator"), headers: authHeader(accessToken));
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

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
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
            pageName: "Moderators",
            context: context,
            header: "Create new Moderator",
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              dataTableContainer(
                  headerPadding: 8,
                  paddingBottom: 0,
                  title: "Assign an Existing Registered User",
                  isScrollableWidget: false,
                  child: Row(children: [
                    Expanded(flex: 3, child: primaryTextField(labelText: "User Email Address", controller: existingUserEmailController)),
                    Expanded(
                        flex: 1,
                        child: primaryButton(
                            paddingBottom: 24,
                            paddingTop: 4,
                            title: "Confirm",
                            onTap: () async {
                              await assignUserToRole(
                                  accessToken: accessToken,
                                  email: existingUserEmailController.text,
                                  onSuccess: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return viewInformationAfterAssign(context: context, onSubmit: () async => route(context, const Moderators()), email: existingUserEmailController.text, role: "Moderator");
                                      }));
                            }))
                  ])),
              dataTableContainer(
                  headerPadding: 8,
                  paddingBottom: 0,
                  title: "Or, Create & Assign a Completely New User",
                  isScrollableWidget: false,
                  child: Column(children: [
                    Row(children: [Expanded(flex: 6, child: primaryTextField(controller: nameController, labelText: "Full Name", keyboardType: TextInputType.name, required: true, errorText: "Name required"))]),
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
                                await doSignUp(
                                    email: emailController.text,
                                    name: nameController.text,
                                    onSuccess: () => showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return viewInformationAfterSignUp(
                                              password: newRandomPassword,
                                              name: nameController.text,
                                              role: "Moderator",
                                              context: context,
                                              email: emailController.text,
                                              onSubmit: () async => route(context, const Moderators()));
                                        }),
                                    phone: phoneController.text);
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
          const SizedBox(height: 6)
        ]),
        actions: [
          Column(children: [primaryButton(icon: Icons.done, title: "Done", onTap: onSubmit)])
        ]);
  }
}
