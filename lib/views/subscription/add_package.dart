import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/components.dart';
import 'package:hi_society_admin/views/all_buildings/all_buildings.dart';
import 'package:hi_society_admin/views/subscription/packages.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';

class AddPackage extends StatefulWidget {
  const AddPackage({Key? key, this.data}) : super(key: key);
  final Map? data;

  @override
  State<AddPackage> createState() => _AddPackageState();
}

class _AddPackageState extends State<AddPackage> {
  //variable
  String accessToken = "";
  final _formKey = GlobalKey<FormState>();
  late TextEditingController packageNameController = TextEditingController(text: widget.data == null ? "" : widget.data!["name"].toString());
  late TextEditingController descriptionController = TextEditingController(text: widget.data == null ? "" : widget.data!["description"].toString());
  late TextEditingController costController = TextEditingController(text: widget.data == null ? "" : widget.data!["cost"].toString());
  late TextEditingController flatLimitController = TextEditingController(text: widget.data == null ? "1" : widget.data!["flatLimit"].toString());
  final TextEditingController validityTimeController = TextEditingController(text: "30 (Fixed)");
  late TextEditingController bufferTimeController = TextEditingController(text: widget.data == null ? "7" : widget.data!["bufferTime"].toString());

  //APIs
  Future<void> createPackage({required String accessToken, required VoidCallback successRoute}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/package/create"),
          headers: authHeader(accessToken),
          body: jsonEncode({
            "name": packageNameController.text,
            "description": descriptionController.text,
            "cost": int.parse(costController.text),
            "flatLimit": int.parse(flatLimitController.text),
            "bufferTime": int.parse(bufferTimeController.text)
          }));
      Map result = jsonDecode(response.body);
      print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        if (kDebugMode) showSnackBar(context: context, label: result["message"]);
        successRoute.call();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> updatePackage({required String accessToken, required VoidCallback successRoute}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/package/update"),
          headers: authHeader(accessToken),
          body: jsonEncode({
            "subscriptionPackageId": widget.data!["subscriptionPackageId"],
            "name": packageNameController.text,
            "description": descriptionController.text,
            "cost": int.parse(costController.text),
            "flatLimit": int.parse(flatLimitController.text),
            "bufferTime": int.parse(bufferTimeController.text)
          }));
      Map result = jsonDecode(response.body);
      print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        if (kDebugMode) showSnackBar(context: context, label: result["message"]);
        successRoute.call();
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
            pageName: "Subscription",
            context: context,
            header: widget.data == null ? "Create a New Monthly Package" : "Edit Package : ${widget.data!["name"]}",
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              dataTableContainer(
                  headerPadding: 8,
                  paddingBottom: 0,
                  title: "Package Information",
                  isScrollableWidget: false,
                  child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(flex: 2, child: primaryTextField(controller: packageNameController, labelText: "Package Name", keyboardType: TextInputType.name, required: true, errorText: "Name required")),
                          Expanded(
                              flex: 1, child: primaryTextField(controller: costController, labelText: "Price", hintText: "BDT", keyboardType: TextInputType.number, required: true, errorText: "Price required"))
                        ]),
                        primaryTextField(
                            controller: descriptionController,
                            labelText: "Package Description",
                            hintText: "Point by Point",
                            keyboardType: TextInputType.multiline,
                            required: true,
                            errorText: "Description required",
                            maxLines: 6),
                        Row(children: [
                          Expanded(child: primaryTextField(labelText: "Flat Limit", controller: flatLimitController, keyboardType: TextInputType.number, required: true)),
                          Expanded(child: primaryTextField(labelText: "Validity Days", controller: validityTimeController, keyboardType: TextInputType.number, required: true, isDisable: true)),
                          Expanded(child: primaryTextField(labelText: "Buffer Days", controller: bufferTimeController, keyboardType: TextInputType.number, required: true))
                        ]),
                        primaryButton(
                            paddingBottom: 24,
                            paddingTop: 4,
                            width: 180,
                            title: widget.data == null ? "Submit" : "Update",
                            onTap: () async {
                              if (_formKey.currentState!.validate()) {
                                widget.data == null
                                    ? await createPackage(accessToken: accessToken, successRoute: () => showSuccess(context: context, label: "New Package Added", onTap: () => route(context, const Packages())))
                                    : await updatePackage(accessToken: accessToken, successRoute: () => showSuccess(context: context, label: "Package Updated", onTap: () => route(context, const Packages())));
                              } else {
                                showSnackBar(context: context, label: "Invalid Entry! Please Check");
                              }
                            })
                      ])))
            ])));
  }
}
