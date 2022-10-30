import 'package:flutter/material.dart';
import 'package:hi_society_admin/create_building_guard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api.dart';
import 'main.dart';

class AllBuildings extends StatefulWidget {
  const AllBuildings({Key? key}) : super(key: key);

  @override
  State<AllBuildings> createState() => _AllBuildingsState();
}

class _AllBuildingsState extends State<AllBuildings> {
  //Variables
  String accessToken = "";
  dynamic apiResult;

//APIs
  Future<void> readAllBuilding({required String accessToken}) async {
    try {
      var response = await http.get(Uri.parse("$baseUrl/building/list"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => apiResult = result["data"]);
        //todo: if success
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken")!);
    await readAllBuilding(accessToken: accessToken);
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
      appBar: primaryAppBar(context: context, title: "All Registered Buildings"),
      body: apiResult == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: apiResult.length,
              itemBuilder: (context, index) => basicListTile(
                    context: context,
                    address: apiResult[index]["address"],
                    // title: apiResult[index]["buildingId"].toString(),
                    title: apiResult[index]["buildingName"],
                    onTap: () => route(context, CreateBuildingGuardApp(buildingID: apiResult[index]["buildingId"])),
                  )),
    );
  }
}
