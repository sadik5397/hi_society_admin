import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class ExportData extends StatefulWidget {
  const ExportData({Key? key}) : super(key: key);

  @override
  State<ExportData> createState() => _ExportDataState();
}

class _ExportDataState extends State<ExportData> {
  //Variables
  String accessToken = "";
  List allBuildingResult = [];
  List allUserResult = [];
  Duration? executionTime;
  double allBuildingResultProgress = 0;
  double allUserResultProgress = 0;

  //API
  Future<void> readAllBuilding({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/building/list/with-status"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => allBuildingResult = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> readAllUser({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/list?limit=10000"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => allUserResult = result["data"]);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  //Function
  Future<void> allBuildingsExportToExcel() async {
    final stopwatch = Stopwatch()..start();
    await readAllBuilding(accessToken: accessToken);
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet()!];
    //region header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = "Building Serial";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = "Building Unique ID";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = "Building Name";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = "Building Address";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = "Approval Status";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = "Contact Person Name";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = "Contact Person Phone";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0)).value = "Contact Person Email";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0)).value = "Total Flats";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0)).value = "Building Picture";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0)).value = "Access Point Email";
    //endregion
    for (int i = 0; i < allBuildingResult.length; i++) {
      //region data
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = allBuildingResult[i]["buildingId"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = allBuildingResult[i]["uniqueId"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = allBuildingResult[i]["buildingName"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = allBuildingResult[i]["address"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = allBuildingResult[i]["approvalStatus"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = allBuildingResult[i]["createdBy"] == null ? "" : allBuildingResult[i]["createdBy"]["name"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = allBuildingResult[i]["createdBy"] == null
          ? ""
          : (allBuildingResult[i]["createdBy"]["phone"] == "00000000000" || allBuildingResult[i]["createdBy"]["phone"] == "___________")
              ? ""
              : allBuildingResult[i]["createdBy"]["phone"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 1)).value = allBuildingResult[i]["createdBy"] == null ? "" : allBuildingResult[i]["createdBy"]["email"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: i + 1)).value = allBuildingResult[i]["flats"].length;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: i + 1)).value = allBuildingResult[i]["photo"] == null ? "" : '$baseUrl/photos/${allBuildingResult[i]["photo"]}';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: i + 1)).value = allBuildingResult[i]["guard"] == null ? "" : allBuildingResult[i]["guard"]["email"].toString();
      //endregion
      setState(() => allBuildingResultProgress = allBuildingResultProgress + 100 / allBuildingResult.length);
    }
    excel.save(fileName: "AllBuildingData - ${DateFormat('dd MMM yyyy - hh.mm a').format(DateTime.now())}.xlsx");
    setState(() => executionTime = stopwatch.elapsed);
    showSuccess(context: context, title: "Exported in ${(executionTime?.inMilliseconds)! / 1000} Seconds");
  }

  Future<void> allUsersExportToExcel() async {
    final stopwatch = Stopwatch()..start();
    await readAllUser(accessToken: accessToken);
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet()!];
    //region header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = "User ID";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = "Full Name";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = "Email";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = "Phone";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = "Gender";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = "Profile Picture";
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = "Hi Society Role";
    //endregion
    for (int i = 0; i < allUserResult.length; i++) {
      //region data
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = allUserResult[i]["userId"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = allUserResult[i]["name"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = allUserResult[i]["email"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value =
          (allUserResult[i]["phone"] == "00000000000" || allUserResult[i]["phone"] == "___________") ? "" : allUserResult[i]["phone"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = allUserResult[i]["gender"].toString();
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = allUserResult[i]["photo"] == null ? "" : '$baseUrl/photos/${allUserResult[i]["photo"]}';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = allUserResult[i]["role"] == null ? "" : allUserResult[i]["role"]["role"].toString();
      //endregion
      setState(() => allUserResultProgress = allUserResultProgress + 100 / allUserResult.length);
    }
    excel.save(fileName: "AllUserData - ${DateFormat('dd MMM yyyy - hh.mm a').format(DateTime.now())}.xlsx");
    setState(() => executionTime = stopwatch.elapsed);
    showSuccess(context: context, title: "Exported in ${(executionTime?.inMilliseconds)! / 1000} Seconds");
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
            pageName: "Export Data",
            context: context,
            header: "Export Data as Excel",
            child: Column(children: [
              dataTableContainer(
                  paddingBottom: 0,
                  title: "All Buildings Data",
                  child: LinearProgressIndicator(value: allBuildingResultProgress, backgroundColor: primaryColor.withOpacity(.25)),
                  isScrollableWidget: false,
                  headerPadding: 0,
                  primaryButtonText: allBuildingResult.isEmpty ? "Calculate Size" : "Total Rows: ${allBuildingResult.length}",
                  primaryButtonOnTap: () async => await readAllBuilding(accessToken: accessToken),
                  showPlusButton: false,
                  entryCount: allBuildingResult.length,
                  secondaryButtonText: "Download Excel",
                  secondaryButtonOnTap: () async => await allBuildingsExportToExcel()),
              dataTableContainer(
                  paddingBottom: 0,
                  title: "All User Data",
                  child: LinearProgressIndicator(value: allUserResultProgress, backgroundColor: primaryColor.withOpacity(.25)),
                  isScrollableWidget: false,
                  headerPadding: 0,
                  primaryButtonText: allUserResult.isEmpty ? "Calculate Size" : "Total Rows: ${allUserResult.length}",
                  primaryButtonOnTap: () async => await readAllUser(accessToken: accessToken),
                  showPlusButton: false,
                  entryCount: allUserResult.length,
                  secondaryButtonText: "Download Excel",
                  secondaryButtonOnTap: () async => await allUsersExportToExcel())
            ])));
  }
}
