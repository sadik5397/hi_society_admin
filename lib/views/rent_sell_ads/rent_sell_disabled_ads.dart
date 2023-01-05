// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class RentSellDisabledAds extends StatefulWidget {
  const RentSellDisabledAds({Key? key}) : super(key: key);

  @override
  State<RentSellDisabledAds> createState() => _RentSellDisabledAdsState();
}

class _RentSellDisabledAdsState extends State<RentSellDisabledAds> {
//Variables
  String accessToken = "";
  List adList = [];

//APIs
  Future<void> readDisabledAdList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/apartment-ads/list/deactivated"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => adList = result["data"].reversed.toList());
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> updateUserPassword({required String accessToken, required String newPassword, required String confirmPassword, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/user/update/password/by-admin"),
          headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "password": newPassword, "confirmPassword": confirmPassword}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(newPassword);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Password Updated", onTap: () => routeBack(context));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
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
    String base64Str = payload.toString();
    try {
      if (kDebugMode) print(jsonEncode({"userId": userId, "payload": base64Str}));
      var response = await http.post(Uri.parse("$baseUrl/push/send/by-user"), headers: authHeader(accessToken), body: jsonEncode({"userId": userId, "payload": base64Str}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(context: context, label: "Notification Sent!", onTap: () => routeBack(context));
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
        //todo: if error
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> reActiveAd({required String accessToken, required int adId}) async {
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
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> disableAd({required String accessToken, required int adId}) async {
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
    await readDisabledAdList(accessToken: accessToken);
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
            header: "Apartment Rent/Sell Ads Moderation",
            child: dataTableContainer(
                entryCount: adList.length,
                secondaryButtonOnTap: () => routeBack(context),
                secondaryButtonText: "Active Ad",
                showPlusButton: false,
                headerRow: ["Title", "Created by", "Photos", "Status", "Actions"],
                flex: [3, 3, 6, 2, 2],
                title: "All Disabled Ads",
                child: (adList.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: adList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(
                                  flex: 3, title: adList[index]["title"].toString(), subtitle: 'Type: ${(adList[index]["adType"].toString().toUpperCase())}', hideImage: true, color: Colors.redAccent),
                              dataTableListTile(
                                  flex: 3, title: adList[index]["createdBy"]["name"], subtitle: 'Posted on: ${adList[index]["updatedAt"].toString().split("T")[0]}', hideImage: true, color: Colors.redAccent),
                              dataTableNetworkImages(flex: 6, images: adList[index]["photos"], onTap: () {}),
                              dataTableChip(flex: 2, label: adList[index]["inactive"] ? "Disabled" : "Active", color: Colors.redAccent),
                              dataTableIcon(toolTip: "View Details", onTap: () {}, icon: Icons.open_in_new_rounded),
                              dataTableIcon(
                                  toolTip: "Enable Ad",
                                  onTap: () async => await showPrompt(
                                      context: context,
                                      onTap: () async {
                                        routeBack(context);
                                        adList[index]["inactive"]
                                            ? await reActiveAd(accessToken: accessToken, adId: adList[index]["advertId"])
                                            : await disableAd(accessToken: accessToken, adId: adList[index]["advertId"]);
                                      }),
                                  icon: adList[index]["inactive"] ? Icons.visibility_outlined : Icons.disabled_visible_rounded,
                                  color: adList[index]["inactive"] ? Colors.green : Colors.redAccent)
                            ])))));
  }
}
