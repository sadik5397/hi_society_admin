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

class SocialMediaPosts extends StatefulWidget {
  const SocialMediaPosts({Key? key}) : super(key: key);

  @override
  State<SocialMediaPosts> createState() => _SocialMediaPostsState();
}

class _SocialMediaPostsState extends State<SocialMediaPosts> {
//Variables
  String accessToken = "";
  List postList = [];

//APIs
  Future<void> readPostList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/social-media/list/post?limit=30"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => postList = result["data"].reversed.toList());
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

  Future<void> reActivePost({required String accessToken, required int postId, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/social-media/mod/restore/post"), headers: authHeader(accessToken), body: jsonEncode({"postId": postId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(
            context: context,
            label: "Marked as Appropriate",
            title: "Post Restored",
            onTap: () async {
              routeBack(context);
              await defaultInit();
            });
        await sendNotification(accessToken: accessToken, title: "Your 'Social Media Post' restored", body: "Your post is now visible to every user", userId: userId);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> disablePost({required String accessToken, required int postId, required int userId}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/social-media/mod/remove/post"), headers: authHeader(accessToken), body: jsonEncode({"postId": postId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(
            context: context,
            label: "Marked as Inappropriate",
            title: "Post Disabled",
            onTap: () async {
              routeBack(context);
              await defaultInit();
            });
        await sendNotification(accessToken: accessToken, title: "Your 'Social Media Post' taken down", body: "Your post removed because it is marked as inappropriate", userId: userId);
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
    await readPostList(accessToken: accessToken);
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
            pageName: "Social Media Posts",
            context: context,
            header: "Social Media Posts Moderation",
            child: dataTableContainer(
                primaryButtonOnTap: () => route(context, const RentSellDisabledAds()),
                primaryButtonText: "Removed Posts",
                entryCount: postList.length,
                headerRow: ["Created by", "Photo", "Post", "Status", "Actions"],
                flex: [2, 3, 2, 2, 2],
                title: "All Active Posts",
                showPlusButton: false,
                child: (postList.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: postList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(flex: 2, title: postList[index]["title"].toString(), subtitle: 'Type: ${(postList[index]["adType"].toString().toUpperCase())}', hideImage: true),
                              dataTableListTile(flex: 2, title: postList[index]["createdBy"]["name"], subtitle: 'Posted on: ${postList[index]["updatedAt"].toString().split("T")[0]}', hideImage: true),
                              dataTableNetworkImages(flex: 4, images: postList[index]["photos"], onTap: () {}),
                              dataTableChip(flex: 2, label: postList[index]["inactive"] ? "Disabled" : "Active"),
                              dataTableIcon(
                                  toolTip: "View Details",
                                  onTap: () => route(
                                      context,
                                      RentSellAdDetails(
                                          userId: postList[index]["createdBy"]["userId"],
                                          adId: postList[index]["advertId"],
                                          status: (postList[index]["inactive"] ? "Disabled" : "Active").toUpperCase(),
                                          title: postList[index]["title"].toString(),
                                          imageList: postList[index]["photos"])),
                                  icon: Icons.open_in_new_rounded),
                              dataTableIcon(
                                  toolTip: "Remove Ad",
                                  onTap: () async => await showPrompt(
                                      context: context,
                                      onTap: () async {
                                        routeBack(context);
                                        postList[index]["inactive"]
                                            ? await reActivePost(accessToken: accessToken, postId: postList[index]["advertId"], userId: postList[index]["createdBy"]["userId"])
                                            : await disablePost(accessToken: accessToken, postId: postList[index]["advertId"], userId: postList[index]["createdBy"]["userId"]);
                                      }),
                                  icon: postList[index]["inactive"] ? Icons.visibility_outlined : Icons.disabled_visible_rounded,
                                  color: postList[index]["inactive"] ? Colors.green : Colors.redAccent)
                            ])))));
  }
}
