import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/building_utility_contacts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../components.dart';

class UtilityContacts extends StatefulWidget {
  const UtilityContacts({Key? key}) : super(key: key);

  @override
  State<UtilityContacts> createState() => _UtilityContactsState();
}

class _UtilityContactsState extends State<UtilityContacts> {
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
      body: includeDashboard(
          pageName: "Contacts",
          context: context,
          header: "All Utility Contacts of Building",
          child: apiResult == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: apiResult.length,
                  itemBuilder: (context, index) => basicListTile(
                        context: context,
                        subTitle: apiResult[index]["address"],
                        title: apiResult[index]["buildingName"],
                        onTap: () => route(context, const BuildingUtilityContacts()), //todo:
                      ))),
    );
  }
}
