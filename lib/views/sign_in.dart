import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/all_buildings/all_buildings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../components.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
//Variables
  String accessToken = "";
  bool loadingWait = false;
  bool showPassword = false;
  final TextEditingController emailController = TextEditingController(text: "admin@lh.com");
  final TextEditingController passwordController = TextEditingController(text: "1234");
  final _formKey = GlobalKey<FormState>();
  dynamic apiResult = {};

//APIs
  Future<void> doSignIn({required String email, required String password, required VoidCallback showHome}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/auth/login"), headers: primaryHeader, body: jsonEncode({"email": email, "password": password}));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => apiResult = result["data"]);
        final pref = await SharedPreferences.getInstance();
        await pref.setString("accessToken", apiResult["accessToken"]);
        setState(() => accessToken = apiResult["accessToken"]);
        showHome.call();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

//Functions
  defaultInit() async {}

//Initiate
  @override
  void initState() {
    super.initState();
    defaultInit();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            body: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/dhaka.jpg"), fit: BoxFit.cover)),
                child: Container(
                    alignment: Alignment.center,
                    color: Colors.black.withOpacity(.65),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/logo.png", width: 250),
                        Container(
                            margin: const EdgeInsets.only(top: 36, bottom: 24),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(42), color: Colors.white.withOpacity(.9)),
                            padding: const EdgeInsets.all(48),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                              const Text("Welcome!\nLogin to Hi Society Admin Dashboard", textAlign: TextAlign.center),
                              const SizedBox(height: 36),
                              Form(
                                  key: _formKey,
                                  child: Column(children: [
                                    primaryTextField(
                                        autofillHints: AutofillHints.email,
                                        width: 400,
                                        controller: emailController,
                                        labelText: "Enter Email or Username",
                                        keyboardType: TextInputType.emailAddress,
                                        autoFocus: true,
                                        required: true,
                                        errorText: "Username/Email required",
                                        textCapitalization: TextCapitalization.none),
                                    primaryTextField(
                                        autofillHints: AutofillHints.password,
                                        width: 400,
                                        controller: passwordController,
                                        labelText: "Enter Password",
                                        isPassword: true,
                                        required: true,
                                        errorText: "Password required",
                                        textCapitalization: TextCapitalization.none,
                                        showPassword: showPassword,
                                        showPasswordPressed: () => setState(() => showPassword = !showPassword))
                                  ])),
                              Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: primaryButton(
                                      // loadingWait: loadingWait,
                                      width: 400,
                                      title: "Login to Admin Dashboard",
                                      onTap: () async {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        // setState(() => loadingWait = true);
                                        if (_formKey.currentState!.validate()) {
                                          await doSignIn(email: emailController.text.toLowerCase(), password: passwordController.text, showHome: () => route(context, const AllBuildings()));
                                        } else {
                                          showSnackBar(context: context, label: "Invalid Entry! Please Check");
                                        }
                                        // setState(() => loadingWait = false);
                                      }))
                            ])),
                      ],
                    )))));
  }
}
