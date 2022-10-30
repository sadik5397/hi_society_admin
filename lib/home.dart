import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'all_buildings.dart';
import 'main.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //Variables
  String? accessToken, buildingName, buildingAddress, buildingImg;
  dynamic apiResult;

// APIs
  Future<void> readBuildingInfo({required String accessToken}) async {
    try {
      var response = await http.get(Uri.parse("$baseUrl/building/info/by-guard"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["code"] == 200) showSnackBar(context: context, label: result["response"]); //success
      if (result["code"] != 200) showSnackBar(context: context, label: result["message"]); //error
      setState(() => apiResult = result["data"]);
      setState(() => buildingName = apiResult["buildingName"]);
      setState(() => buildingAddress = apiResult["address"]);
      setState(() => buildingImg = "https://source.unsplash.com/random/?building");
      final pref = await SharedPreferences.getInstance();
      await pref.setString("buildingName", apiResult["buildingName"]);
      await pref.setString("buildingAddress", apiResult["address"]);
      await pref.setInt("buildingID", apiResult["buildingId"]);
      await pref.setString("buildingUniqueID", apiResult["uniqueId"]);
      await pref.setString("buildingImg", "https://source.unsplash.com/random/?building");
    } on Exception catch (e) {
      showSnackBar(context: context, label: e.toString());
    }
  }

//Functions
  defaultInit() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => accessToken = pref.getString("accessToken"));
    setState(() => buildingName = pref.getString("buildingName"));
    setState(() => buildingAddress = pref.getString("buildingAddress"));
    setState(() => buildingImg = pref.getString("buildingImg"));
    await readBuildingInfo(accessToken: accessToken!);
  }

//Initiate
  @override
  void initState() {
    super.initState();
    defaultInit();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        child: Scaffold(
            appBar: primaryAppBar(context: context),
            body: GridView(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, mainAxisSpacing: 12, crossAxisSpacing: 12),
              children: [
                menuGridTile(title: "All Buildings", assetImage: "apartment", context: context, toPage: const AllBuildings()),
              ],
            )));
  }
}
