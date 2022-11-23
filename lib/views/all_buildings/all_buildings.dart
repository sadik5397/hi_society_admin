import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import '../../components.dart';
import 'update_building.dart';

class AllBuildings extends StatefulWidget {
  const AllBuildings({Key? key}) : super(key: key);

  @override
  State<AllBuildings> createState() => _AllBuildingsState();
}

class _AllBuildingsState extends State<AllBuildings> {
  //Variables
  String accessToken = "";
  List apiResult = [];

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
            pageName: "All Buildings",
            context: context,
            header: "All Registered Buildings",
            child: dataTableContainer(
                title: "All Buildings",
                headerRow: ["Building Name", "Status", "Contact", "Acton"],
                flex: [3, 1, 2, 1],
                entryCount: apiResult.length,
                primaryButtonOnTap: () {},
                child: apiResult.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: apiResult.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(
                            index: index,
                            child: Row(children: [
                              dataTableListTile(flex: 3, title: apiResult[index]["buildingName"], subtitle: 'Address: ${apiResult[index]["address"]}'),
                              (apiResult[index]["guard"] != null) ? dataTableChip(flex: 1, label: "Active") : dataTableNull(),
                              dataTableSingleInfo(flex: 2, title: "+8801515644470"), //todo: Need Contact Person Phone Number
                              dataTableIcon(
                                  onTap: () => route(
                                      context,
                                      UpdateBuilding(
                                          buildingName: apiResult[index]["buildingName"],
                                          buildingID: apiResult[index]["buildingId"],
                                          guard: (apiResult[index]["guard"] != null) ? apiResult[index]["guard"] : {"result": "null"})),
                                  icon: Icons.edit)
                            ]))))));
  }
}
