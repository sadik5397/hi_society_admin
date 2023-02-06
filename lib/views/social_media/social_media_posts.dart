// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/social_media/social_media_disabled_posts.dart';
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
  String myRole = "";
  List postList = [];

//APIs
  Future<void> readPostList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/social-media/list/post?limit=30"), headers: authHeader(accessToken));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSnackBar(context: context, label: result["message"]);
        setState(() => postList = result["data"]);
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
        await sendNotification(accessToken: accessToken, title: "Your Social Media Post restored", body: "Your post is now visible to every user", userId: userId);
      } else {
        showError(context: context, label: result["message"][0].toString().length == 1 ? result["message"].toString() : result["message"][0].toString());
      }
    } on Exception catch (e) {
      showError(context: context, label: e.toString());
    }
  }

  Future<void> disablePost({required String accessToken, required int postId, required int userId, required String reason}) async {
    print("$baseUrl/social-media/mod/remove/post");
    print({"postId": postId});
    try {
      var response = await http.post(Uri.parse("$baseUrl/social-media/mod/remove/post"), headers: authHeader(accessToken), body: jsonEncode({"postId": postId}));
      Map result = jsonDecode(response.body);
      if (kDebugMode) print(result);
      if (result["statusCode"] == 200 || result["statusCode"] == 201) {
        showSuccess(
            context: context,
            label: reason,
            title: "Post Disabled",
            onTap: () async {
              route(context, const SocialMediaPosts());
            });
        await sendNotification(accessToken: accessToken, title: "Your Social Media Post taken down", body: "Reason: $reason", userId: userId);
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
            isAdmin: myRole == "admin",
            pageName: "Social Media Posts",
            context: context,
            header: "Social Media Posts Moderation",
            child: dataTableContainer(
                primaryButtonOnTap: () => route(context, const SocialMediaDisabledPosts()),
                primaryButtonText: "Removed Posts",
                entryCount: postList.length,
                headerRow: ["Created by", "Photo", "Post", "Status", "Actions"],
                flex: [2, 3, 2, 2, 1],
                title: "All Active Posts",
                showPlusButton: false,
                child: (postList.isEmpty)
                    ? const Center(child: NoData())
                    : ListView.builder(
                        itemCount: postList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(
                                  flex: 2,
                                  title: postList[index]["user"]["name"],
                                  subtitle: 'Posted on: ${postList[index]["createdAt"].toString().split("T")[0]}',
                                  hideImage: false,
                                  img: postList[index]["user"]["photo"] == null ? placeholderImage : '$baseUrl/photos/${postList[index]["user"]["photo"]}'),
                              dataTableNetworkImagesForSocialMedia(flex: 3, images: postList[index]["photos"] ?? []),
                              dataTableSingleInfo(flex: 2, title: postList[index]["miniContent"]),
                              dataTableChip(flex: 2, label: "Active"),
                              dataTableIcon(
                                  toolTip: "Remove Post",
                                  onTap: () async => showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: const Center(child: Text("Disable Reason")),
                                            insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 200),
                                            buttonPadding: EdgeInsets.zero,
                                            content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: List.generate(
                                                    qaReason.length,
                                                    (index) => primaryButton(
                                                        allCapital: false,
                                                        primary: false,
                                                        title: qaReason[index],
                                                        onTap: () async {
                                                          await showPrompt(
                                                              context: context,
                                                              onTap: () async {
                                                                routeBack(context);
                                                                await disablePost(
                                                                    accessToken: accessToken, postId: postList[index]["postId"], userId: postList[index]["user"]["userId"], reason: qaReason[index]);
                                                              });
                                                        }))));
                                      }),
                                  icon: Icons.disabled_visible_rounded,
                                  color: Colors.redAccent)
                            ])))));
  }
}
