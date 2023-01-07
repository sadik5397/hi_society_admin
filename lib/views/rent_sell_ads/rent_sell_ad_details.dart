// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class RentSellAdDetails extends StatefulWidget {
  const RentSellAdDetails({Key? key, required this.adId, required this.title, required this.imageList, required this.status, required this.userId}) : super(key: key);
  final int adId;
  final int userId;
  final String title;
  final String status;
  final List imageList;

  @override
  State<RentSellAdDetails> createState() => _RentSellAdDetailsState();
}

class _RentSellAdDetailsState extends State<RentSellAdDetails> {
//Variables
  String accessToken = "";
  Map<String, dynamic> apiResult = {};

//APIs
  Future<void> readAdDetail({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/apartment-ads/view?adId=${widget.adId}"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => apiResult = result["data"]);
      } else {
        showSnackBar(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> sendNotification({required String accessToken, required String title, required String body, required int userId}) async {
    Map payload = {
      "notification": {"title": title, "body": body},
      "data": {"topic": "announcement"}
    };
    String base64Str = json.encode(payload);
    try {
      if (kDebugMode) print(jsonEncode({"userId": userId, "payload": base64Str}));
      var response = await http.post(Uri.parse("$baseUrl/push/send/by-user"), headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "payload": base64Str}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        // showSuccess(context: context, label: "Notification Sent!", onTap: () => routeBack(context));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> reActiveAd({required String accessToken, required int adId, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/apartment-ads/reactivate?adId=$adId"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(
            context: context,
            label: "Marked as Appropriate",
            title: "Ad Enabled",
            onTap: () async {
              routeBack(context);
              await defaultInit();
            });
        await sendNotification(accessToken: accessToken, title: "Your Apartment Rent-Sell Ad re-activated", body: "Your ad is now visible to every user", userId: userId);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> disableAd({required String accessToken, required int adId, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/apartment-ads/deactivate?adId=$adId"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(
            context: context,
            label: "Marked as Inappropriate",
            title: "Ad Disabled",
            onTap: () async {
              routeBack(context);
              await defaultInit();
            });
        await sendNotification(accessToken: accessToken, title: "Your Apartment Rent-Sell Ad taken down", body: "Your ad removed because it is marked as inappropriate", userId: userId);
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
    await readAdDetail(accessToken: accessToken);
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
            pageName: "Rent/Sell Ads",
            context: context,
            header: "Apartment Rent/Sell Ad",
            child: dataTableContainer(
                primaryButtonOnTap: () async => widget.status == "ACTIVE"
                    ? await disableAd(accessToken: accessToken, adId: widget.adId, userId: widget.userId)
                    : await reActiveAd(accessToken: accessToken, adId: widget.adId, userId: widget.userId),
                primaryButtonText: widget.status == "ACTIVE" ? "Disable Ad" : "Enable Ad",
                title: widget.title,
                entryStrng: widget.status,
                headerPadding: 0,
                showPlusButton: false,
                child: (ListView(shrinkWrap: true, children: [
                  Padding(
                      padding: const EdgeInsets.all(6),
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: List.generate(
                                  widget.imageList.length,
                                  (index) => Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Image.network(widget.imageList.isEmpty ? placeholderImage : '$baseUrl/photos/${widget.imageList[index]["photoPath"]}', height: 380, fit: BoxFit.fitHeight),
                                      ))))),
                  if (apiResult.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(apiResult["title"], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Row(children: [
                            Text('Posted Date:', style: TextStyle(color: Colors.black87.withOpacity(.7))),
                            Text('  ${(apiResult["createdAt"]).toString().split("T")[0]}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))
                          ]),
                          const SizedBox(height: 12 * 1.25),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 12),
                          Row(children: [
                            Text('৳ ${apiResult["price"]}', style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.bold)),
                            Text(apiResult["adType"] == 'rent' ? '/month' : '/sq ft', style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.normal))
                          ]),
                          Row(children: [
                            Text('Posted By:', style: TextStyle(color: Colors.black87.withOpacity(.7))),
                            Text('  ${apiResult["createdBy"]["name"]}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))
                          ]),
                          const SizedBox(height: 12),
                          const Text('Basic Information:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          Row(children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Location:', style: TextStyle(color: Colors.black87.withOpacity(.7))),
                              Text('Bed Room(s):', style: TextStyle(color: Colors.black87.withOpacity(.7))),
                              Text('Bath Room(s):', style: TextStyle(color: Colors.black87.withOpacity(.7))),
                              Text('Area:', style: TextStyle(color: Colors.black87.withOpacity(.7))),
                              Text('Facing:', style: TextStyle(color: Colors.black87.withOpacity(.7))),
                              Text('Status:', style: TextStyle(color: Colors.black87.withOpacity(.7)))
                            ]),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(apiResult["location"], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text(apiResult["bed"].toString(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text(apiResult["bath"].toString(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text('${apiResult["area"]} sq ft', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text(apiResult["facing"], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text(apiResult["inactive"] == false ? "Available" : "Not Available", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))
                            ])
                          ]),
                          const SizedBox(height: 12),
                          const Text('Building Information:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          Row(children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text('Building Name:', style: TextStyle(color: Colors.black87.withOpacity(.7))), Text('Address:', style: TextStyle(color: Colors.black87.withOpacity(.7)))]),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(apiResult["building"], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text(apiResult["address"], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))
                            ])
                          ]),
                          const SizedBox(height: 12),
                          const Text('Features:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12 / 6),
                          Text(apiResult["feature"], textAlign: TextAlign.start, style: TextStyle(color: Colors.black87.withOpacity(.7), fontWeight: FontWeight.w400)),
                          const SizedBox(height: 12),
                          const Text('Description:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12 / 6),
                          Text(apiResult["description"], textAlign: TextAlign.start, style: TextStyle(color: Colors.black87.withOpacity(.7), fontWeight: FontWeight.w400)),
                          const SizedBox(height: 12),
                          const Text('Contact Information:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12 / 6),
                          Row(children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text('Phone:', style: TextStyle(color: Colors.black87.withOpacity(.7))), Text('Email:', style: TextStyle(color: Colors.black87.withOpacity(.7)))]),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(apiResult["phone"].toString(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              Text(apiResult["email"], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))
                            ])
                          ])
                        ]))
                ])))));
  }
}
