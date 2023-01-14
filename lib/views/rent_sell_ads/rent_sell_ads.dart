// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/rent_sell_ads/rent_sell_ad_details.dart';
import 'package:hi_society_admin/views/rent_sell_ads/rent_sell_disabled_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class RentSellAds extends StatefulWidget {
  const RentSellAds({Key? key}) : super(key: key);

  @override
  State<RentSellAds> createState() => _RentSellAdsState();
}

class _RentSellAdsState extends State<RentSellAds> {
//Variables
  String accessToken = "";
  String myRole = "";
  List adList = [];

//APIs
  Future<void> readAdList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/apartment-ads/list?limit=30"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => adList = result["data"].reversed.toList());
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
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
    setState(() => myRole = pref.getString("role") ?? "");
    await readAdList(accessToken: accessToken);
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
            isAdmin: myRole == "admin",
            pageName: "Rent/Sell Ads",
            context: context,
            header: "Apartment Rent/Sell Ads Moderation",
            child: dataTableContainer(
                primaryButtonOnTap: () => route(context, const RentSellDisabledAds()),
                primaryButtonText: "Disabled Ads",
                entryCount: adList.length,
                headerRow: ["Title", "Created by", "Photos", "Status", "Actions"],
                flex: [2, 2, 4, 2, 2],
                title: "All Active Ads",
                showPlusButton: false,
                child: (adList.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: adList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(flex: 2, title: adList[index]["title"].toString(), subtitle: 'Type: ${(adList[index]["adType"].toString().toUpperCase())}', hideImage: true),
                              dataTableListTile(flex: 2, title: adList[index]["createdBy"]["name"], subtitle: 'Posted on: ${adList[index]["createdAt"].toString().split("T")[0]}', hideImage: true),
                              dataTableNetworkImagesForAds(flex: 4, images: adList[index]["photos"] ?? [], onTap: () {}),
                              dataTableChip(flex: 2, label: adList[index]["inactive"] ? "Disabled" : "Active"),
                              dataTableIcon(
                                  toolTip: "View Details",
                                  onTap: () => route(
                                      context,
                                      RentSellAdDetails(
                                          userId: adList[index]["createdBy"]["userId"],
                                          adId: adList[index]["advertId"],
                                          status: (adList[index]["inactive"] ? "Disabled" : "Active").toUpperCase(),
                                          title: adList[index]["title"].toString(),
                                          imageList: adList[index]["photos"])),
                                  icon: Icons.open_in_new_rounded),
                              dataTableIcon(
                                  toolTip: "Remove Ad",
                                  onTap: () async => await showPrompt(
                                      context: context,
                                      onTap: () async {
                                        routeBack(context);
                                        adList[index]["inactive"]
                                            ? await reActiveAd(accessToken: accessToken, adId: adList[index]["advertId"], userId: adList[index]["createdBy"]["userId"])
                                            : await disableAd(accessToken: accessToken, adId: adList[index]["advertId"], userId: adList[index]["createdBy"]["userId"]);
                                      }),
                                  icon: adList[index]["inactive"] ? Icons.visibility_outlined : Icons.disabled_visible_rounded,
                                  color: adList[index]["inactive"] ? Colors.green : Colors.redAccent)
                            ])))));
  }
}
