import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/components.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api.dart';

class Verification extends StatefulWidget {
  const Verification({Key? key}) : super(key: key);

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  //variable
  String accessToken = "";
  Map data = {};
  bool loaded = false;
  TextEditingController paymentID = TextEditingController();

  //APIs
  Future<void> checkHistory({required String accessToken, required String trxID}) async {
    setState(() => loaded = false);
    try {
      var response = await http.post(Uri.parse("$baseUrl/subscription/paymentID-list?limit=9999"), headers: authHeader(accessToken));
      Map results = jsonDecode(response.body);
      print(results);
      if (results["statusCode"] == 200 || results["statusCode"] == 201) {
        if (kDebugMode) showSnackBar(context: context, label: results["message"]);
        List result = results["data"];
        for (int i = 0; i < result.length; i++) {
          if (result[i]["bkashPaymentId"] == trxID || result[i]["trxId"] == trxID || result[i]["invoiceId"] == trxID) setState(() => data = result[i]);
        }
      } else {
        showError(context: context, label: results["message"][0].toString().length == 1 ? results["message"].toString() : results["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
    setState(() => loaded = true);
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
            pageName: "Verify Payment",
            context: context,
            header: "Payment Verification",
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              dataTableContainer(
                  headerPadding: 8,
                  paddingBottom: 0,
                  title: "Check payment history by Transaction ID / Payment ID / Invoice ID",
                  isScrollableWidget: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(flex: 2, child: primaryTextField(controller: paymentID, labelText: "ID", required: true, errorText: "ID required")),
                      Expanded(
                          flex: 1,
                          child: primaryButton(
                              paddingBottom: 24,
                              paddingTop: 4,
                              width: 180,
                              title: "Check",
                              onTap: () async =>
                                  paymentID.text != "" ? await checkHistory(accessToken: accessToken, trxID: paymentID.text) : showSnackBar(context: context, label: "Invalid Entry! Please Check")))
                    ]),
                    if (loaded)
                      data.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                DataTable(columns: [
                                  DataColumn(label: Text("Key", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor))),
                                  DataColumn(label: Text("Value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)))
                                ], rows: [
                                  DataRow(cells: [
                                    const DataCell(Text("Payment Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["status"].toString().toUpperCase(),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: data["status"].toString().toUpperCase() == "COMPLETED" ? Colors.green : Colors.redAccent)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["paymentMethod"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("bKash Payment ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["bkashPaymentId"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Transaction ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["trxId"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("HiSociety Invoice ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["invoiceId"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Transaction Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["updatedAt"].toString().split("T")[0], style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Payment Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText('BDT ${data["amount"]}', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Payment of", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText('${data["months"]} Month(s)', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                ]),
                                SizedBox(width: 24),
                                DataTable(columns: [
                                  DataColumn(label: Text("Key", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor))),
                                  DataColumn(label: Text("Value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)))
                                ], rows: [
                                  DataRow(cells: [
                                    const DataCell(Text("Building Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["subscription"]["building"]["buildingName"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["subscription"]["building"]["address"].toString(), style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Last Paid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["subscription"]["paidAt"].toString().split("T")[0], style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Expires at", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["subscription"]["expiresAt"].toString().split("T")[0], style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ]),
                                  DataRow(cells: [
                                    const DataCell(Text("Next Subscription", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    DataCell(SelectableText(data["subscription"]["nextSubscriptionAt"].toString().split("T")[0], style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)))
                                  ])
                                ])
                              ]))
                          : Padding(padding: const EdgeInsets.only(bottom: 24), child: NoData())
                  ]))
            ])));
  }
}
