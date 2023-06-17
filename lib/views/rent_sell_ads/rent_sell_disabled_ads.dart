// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/rent_sell_ads/rent_sell_ad_details.dart';
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
  String myRole = "";  String myName = "";

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
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> sendNotification({required String accessToken, required String title, required String body, required int userId}) async {
    Map payload = {
      // "notification": {"title": title, "body": body},
      "data": {"title": title, "body": body,"topic": "announcement"}
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
setState(() => myName = pref.getString("name") ?? "");    await readDisabledAdList(accessToken: accessToken);
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
            isOpMod: myName.split(" | ").length == 2 && myName.split(" | ")[1] == "(Operation)",
            pageName: "Rent/Sell Ads",
            context: context,
            header: "Apartment Rent/Sell Ads Moderation",
            child: dataTableContainer(
                entryCount: adList.length,
                secondaryButtonOnTap: () => routeBack(context),
                secondaryButtonText: "Active Ads",
                showPlusButton: false,
                headerRow: ["Title", "Created by", "Photos", "Status", "Actions"],
                flex: [2, 2, 4, 2, 2],
                title: "All Disabled Ads",
                child: (adList.isEmpty)
                    ? const Center(child: NoData())
                    : ListView.builder(
                        itemCount: adList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(
                                onTap: () => route(
                                    context,
                                    RentSellAdDetails(
                                        userId: adList[index]["createdBy"]["userId"],
                                        adId: adList[index]["advertId"],
                                        status: (adList[index]["inactive"] ? "Disabled" : "Active").toUpperCase(),
                                        title: adList[index]["title"].toString(),
                                        imageList: adList[index]["photos"])),
                                index: index,
                                children: [
                                  dataTableListTile(
                                      flex: 2, title: adList[index]["title"].toString(), subtitle: 'Type: ${(adList[index]["adType"].toString().toUpperCase())}', hideImage: true, color: Colors.redAccent),
                                  dataTableListTile(
                                      flex: 2,
                                      title: adList[index]["createdBy"]["name"],
                                      subtitle: 'Posted on: ${adList[index]["createdAt"].toString().split("T")[0]}',
                                      hideImage: true,
                                      color: Colors.redAccent),
                                  dataTableNetworkImagesForAds(flex: 4, images: adList[index]["photos"] ?? [], onTap: () {}),
                                  dataTableChip(flex: 2, label: adList[index]["inactive"] ? "Disabled" : "Active", color: Colors.redAccent),
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
                                      toolTip: "Enable Ad",
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
