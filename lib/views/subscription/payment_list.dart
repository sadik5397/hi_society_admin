// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';
import '../../components.dart';

class PaymentList extends StatefulWidget {
  const PaymentList({Key? key}) : super(key: key);

  @override
  State<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList> {
//Variables
  String accessToken = "";
  List paymentList = [];
  List foundPayments = [];
  TextEditingController searchController = TextEditingController();
  final Debouncer onSearchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  List<String> statuses = ["Initiated", "Completed", "Error", "Unknown"];
  String? selectedStatus;

//APIs
  Future<void> readPaymentList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/paymentID-list?limit=9999"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => paymentList = result["data"]);
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
    await readPaymentList(accessToken: accessToken);
    setState(() => foundPayments = paymentList);
  }

  void runSearch(String enteredKeyword) {
    setState(() => selectedStatus = null);
    List searchResults = [];
    enteredKeyword.isEmpty
        ? searchResults = paymentList
        : searchResults = (paymentList.where((data) => (data["bkashPaymentId"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["trxId"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["createdAt"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["invoiceId"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["subscription"]["building"]["buildingName"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["subscription"]["building"]["address"].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
            data["updatedAt"].toString().toLowerCase().contains(enteredKeyword.toLowerCase())))).toList();
    setState(() => foundPayments = searchResults);
  }

  void runStatusFilter(String selectedRoleString) {
    runSearch(searchController.text);
    setState(() => selectedStatus = selectedRoleString);
    List searchResults = [];
    if (selectedRoleString == statuses[0]) searchResults = (foundPayments.where((data) => (data["status"].toString().contains("initiated")))).toList();
    if (selectedRoleString == statuses[1]) searchResults = (foundPayments.where((data) => (data["status"].toString().contains("completed")))).toList();
    if (selectedRoleString == statuses[2]) searchResults = (foundPayments.where((data) => (data["status"].toString().contains("error")))).toList();
    if (selectedRoleString == statuses[3]) searchResults = (foundPayments.where((data) => (data["status"].toString().contains("unknown")))).toList();
    setState(() => foundPayments = searchResults);
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
            pageName: "Payment List",
            context: context,
            header: "Payment Statement",
            child: dataTableContainer(
                entryCount: foundPayments.length,
                headerRow: ["Building", "Date", "Amount", "Status", "Action"],
                flex: [1, 1, 1, 1, 1],
                title: "List of Payments",
                searchWidget: Row(children: [
                  primaryTextField(
                      fillColor: primaryColor.withOpacity(.1),
                      bottomPadding: 0,
                      labelText: "Search Anything",
                      icon: Icons.search_rounded,
                      controller: searchController,
                      width: 250,
                      hasSubmitButton: true,
                      textCapitalization: TextCapitalization.words,
                      onFieldSubmitted: (value) => onSearchDebouncer.debounce(() => runSearch(value)),
                      onChanged: (value) => onSearchDebouncer.debounce(() => runSearch(value)),
                      onFieldSubmittedAlternate: () => runSearch(searchController.text)),
                  primaryDropdown(paddingBottom: 0, width: 200, title: "Status", keyTitle: '', options: statuses, value: selectedStatus, onChanged: (value) => runStatusFilter(value.toString()))
                ]),
                child: (foundPayments.isEmpty)
                    ? const Center(child: NoData())
                    : ListView.builder(
                        itemCount: foundPayments.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(
                                onTap: () async => await showDialog(context: context, builder: (BuildContext context) => moreUserOptions(data: foundPayments[index], context: context)),
                                index: index,
                                children: [
                                  dataTableListTile(
                                      hideImage: true,
                                      title: foundPayments[index]["subscription"]["building"]["buildingName"].toString(),
                                      subtitle: foundPayments[index]["subscription"]["building"]["address"].toString()),
                                  dataTableListTile(
                                      hideImage: true, title: foundPayments[index]["createdAt"].toString().split("T")[0], subtitle: foundPayments[index]["createdAt"].toString().split("T")[1].split(".")[0]),
                                  dataTableListTile(
                                      hideImage: true,
                                      title: 'BDT ${foundPayments[index]["amount"]}',
                                      subtitle: foundPayments[index]["bkashPaymentId"].toString() == "null" ? "INVALID Payment" : foundPayments[index]["bkashPaymentId"].toString()),
                                  dataTableChip(label: foundPayments[index]["status"].toString().toUpperCase(), color: foundPayments[index]["status"] == "completed" ? Colors.green : Colors.redAccent),
                                  dataTableIcon(
                                      toolTip: "More Options",
                                      onTap: () async => await showDialog(context: context, builder: (BuildContext context) => moreUserOptions(data: foundPayments[index], context: context)),
                                      icon: Icons.read_more)
                                ])))));
  }
}
