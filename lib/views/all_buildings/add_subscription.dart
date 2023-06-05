import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/all_buildings/all_buildings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import '../../components.dart';

class AddSubscription extends StatefulWidget {
  const AddSubscription({Key? key, required this.buildingID, required this.isNew}) : super(key: key);
  final int buildingID;
  final bool isNew;

  @override
  State<AddSubscription> createState() => _AddSubscriptionState();
}

class _AddSubscriptionState extends State<AddSubscription> {
  //Variables
  String accessToken = "";
  bool isLoading = true;
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  dynamic apiResult;
  FocusNode focusNode = FocusNode();
  String? selectedPackage, selectedMethod, selectedMonth;
  List<String> packageNames = [];
  List<num> packageCost = [];
  List<int> packageIds = [];
  List<String> paymentMethods = ["Cash", "Bank Transfer", "MFS", "Others"];
  List<String> months = List.generate(6, (index) => (index + 1).toString());

//APIs
  Future<void> doSubscribeManually(
      {required String accessToken,
      required String paymentMethod,
      required String transactionId,
      required int months,
      required int packageId,
      required int buildingId,
      required VoidCallback successRoute}) async {
    print(jsonEncode({"buildingId": buildingId, "packageId": packageId, "months": months, "paymentMethod": paymentMethod, "transactionId": transactionId}));
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/create/manual"),
          headers: authHeader(accessToken), body: jsonEncode({"buildingId": buildingId, "packageId": packageId, "months": months, "paymentMethod": paymentMethod, "transactionId": transactionId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        setState(() => apiResult = result["data"]);
        successRoute.call();
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> readAllPackages({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/package/list"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        if (kDebugMode) print(result);
        showSnackBar(context: context, label: result["message"]);
        List packages = result["data"];
        for (int i = 0; i < packages.length; i++) {
          setState(() {
            packageNames.add(packages[i]["name"]);
            packageCost.add(packages[i]["cost"]);
            packageIds.add(packages[i]["subscriptionPackageId"]);
          });
          setState(() => selectedPackage = packageNames[0]);
          setState(() => costController.text = packageCost[0].toString());
          setState(() => selectedMethod = paymentMethods[0].toString());
          setState(() => selectedMonth = months[0].toString());
          setState(() => isLoading = false);
        }
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> doUpdatePackage({required String accessToken, required int packageId, required int buildingId, required bool isNew}) async {
    print("$baseUrl/subscription/${isNew ? 'create' : 'update'}");
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/${isNew ? 'create' : 'update'}"), headers: authHeader(accessToken), body: jsonEncode({"buildingId": buildingId, "packageId": packageId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
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
            isScrollablePage: true,
            pageName: "all buildings",
            context: context,
            header: "Assign Subscription Manually",
            child: isLoading
                ? Padding(padding: const EdgeInsets.all(48), child: NoData())
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    dataTableContainer(
                        title: "Information",
                        isScrollableWidget: false,
                        child: Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(
                                    child: primaryDropdown(
                                        title: "Package",
                                        options: packageNames,
                                        value: selectedPackage,
                                        onChanged: (value) => setState(() {
                                              selectedPackage = value.toString();
                                              costController.text = (int.parse(selectedMonth ?? "1") * packageCost[packageNames.indexOf(selectedPackage ?? "")]).toString();
                                            }))),
                                Expanded(
                                    child: primaryDropdown(
                                        title: "How Months?",
                                        options: months,
                                        value: selectedMonth,
                                        onChanged: (value) => setState(() {
                                              selectedMonth = value.toString();
                                              costController.text = (int.parse(selectedMonth ?? "1") * packageCost[packageNames.indexOf(selectedPackage ?? "")]).toString();
                                            }))),
                                Expanded(child: primaryTextField(labelText: "Payable (BDT)", controller: costController, isDisable: true)),
                                Expanded(child: primaryDropdown(title: "Method", options: paymentMethods, value: selectedMethod, onChanged: (value) => setState(() => selectedMethod = value.toString())))
                              ]),
                              Row(children: [
                                Expanded(child: primaryTextField(controller: referenceController, labelText: "Note/Reference/Description", required: true, errorText: "* Required")),
                                primaryButton(
                                    width: 200,
                                    paddingBottom: 18,
                                    icon: Icons.done_all_rounded,
                                    title: "Confirm",
                                    onTap: () async {
                                      if (_formKey.currentState!.validate()) {
                                        print(widget.isNew.toString());
                                        await doUpdatePackage(accessToken: accessToken, isNew: widget.isNew, packageId: packageIds[packageNames.indexOf(selectedPackage ?? "")], buildingId: widget.buildingID);
                                        await doSubscribeManually(
                                            accessToken: accessToken,
                                            buildingId: widget.buildingID,
                                            months: int.parse(selectedMonth ?? "1"),
                                            packageId: packageIds[packageNames.indexOf(selectedPackage ?? "")],
                                            paymentMethod: selectedMethod ?? "Cash",
                                            transactionId: referenceController.text,
                                            successRoute: () =>
                                                showSuccess(context: context, label: "BDT ${costController.text} $selectedMethod Payment Receive Recorded", onTap: () => route(context, const AllBuildings())));
                                      } else {
                                        showSnackBar(context: context, label: "Invalid Entry! Please Check");
                                      }
                                    })
                              ])
                            ])))
                  ])));
  }
}
