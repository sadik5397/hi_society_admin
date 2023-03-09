// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';
import 'add_package.dart';

class Packages extends StatefulWidget {
  const Packages({Key? key}) : super(key: key);

  @override
  State<Packages> createState() => _PackagesState();
}

class _PackagesState extends State<Packages> {
//Variables
  String accessToken = "";
  List packages = [];

//APIs
  Future<void> readAllPackages({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/package/list"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        if (kDebugMode) print(result);
        showSnackBar(context: context, label: result["message"]);
        setState(() => packages = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  // Future<void> addAmenityCategory({required String accessToken, required String name}) async {
  //   try {
  //     var response = await http.post(Uri.parse("$baseUrl/amenity-booking/create/amenity/category"), headers: authHeader(accessToken), body: jsonEncode({"categoryName": name}));
  //     Map result = jsonDecode(response.body);
  //     if (kDebugMode) print(name);
  //     if (kDebugMode) print(result);
  //     if (result["statusCode"] == 200 || result["statusCode"] == 201) {
  //       showSuccess(context: context, label: "$name Added");
  //       setState(() => packages = result["data"]);
  //     } else {
  //       showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
  //     }
  //   } on Exception catch (e) {
  //     showError(context: context, label: e.toString());
  //   }
  // }
  //
  // Future<void> updateAmenityCategory({required String accessToken, required String name, required int cid}) async {
  //   try {
  //     var response = await http.post(Uri.parse("$baseUrl/amenity-booking/update/amenity/category"), headers: authHeader(accessToken), body: jsonEncode({"categoryName": name, "amenityCategoryId": cid}));
  //     Map result = jsonDecode(response.body);
  //     if (kDebugMode) print(name);
  //     if (kDebugMode) print(result);
  //     if (result["statusCode"] == 200 || result["statusCode"] == 201) {
  //       showSuccess(context: context, label: "Updated to $name");
  //       setState(() => packages = result["data"]);
  //       Navigator.pop(context);
  //     } else {
  //       showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
  //     }
  //   } on Exception catch (e) {
  //     showError(context: context, label: e.toString());
  //   }
  // }
  //
  // Future<void> deleteAmenityCategory({required String accessToken, required int cid}) async {
  //   try {
  //     var response = await http.post(Uri.parse("$baseUrl/amenity-booking/remove/amenity/category"), headers: authHeader(accessToken), body: jsonEncode({"amenityCategoryId": cid}));
  //     Map result = jsonDecode(response.body);
  //     if (kDebugMode) print(result);
  //     if (result["statusCode"] == 200 || result["statusCode"] == 201) {
  //       showSuccess(context: context, label: "Amenity Deleted");
  //       setState(() => packages = result["data"]);
  //     } else {
  //       showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
  //     }
  //   } on Exception catch (e) {
  //     showError(context: context, label: e.toString());
  //   }
  // }

//Functions

  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
    await readAllPackages(accessToken: accessToken);
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
            pageName: "Subscription",
            context: context,
            header: "Subscription Packages",
            child: dataTableContainer(
                entryCount: packages.length,
                // headerRow: ["Category Name", "Status", "Actions"],
                flex: [4, 2, 2],
                primaryButtonOnTap: () => route(context, const AddPackage()),
                title: "Package Details",
                child: (packages.isEmpty)
                    ? const Center(child: NoData())
                    : Align(
                        alignment: Alignment.topLeft,
                        child: SingleChildScrollView(
                          child: Wrap(
                              runAlignment: WrapAlignment.start,
                              children: List.generate(
                                  packages.length,
                                  (index) => packageTile(context: context, package: packages[index]))),
                        )))));
  }
}
