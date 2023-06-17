// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../../components.dart';

class SocialMediaDisabledPosts extends StatefulWidget {
  const SocialMediaDisabledPosts({Key? key}) : super(key: key);

  @override
  State<SocialMediaDisabledPosts> createState() => _SocialMediaDisabledPostsState();
}

class _SocialMediaDisabledPostsState extends State<SocialMediaDisabledPosts> {
//Variables
  String accessToken = "";
  String myRole = "";
  String myName = "";
  List postList = [];

//APIs
  Future<void> readDisabledPostList({required String accessToken}) async {
    try {
      var response = await http.post(Uri.parse("$baseUrl/social-media/mod/list/post?limit=5000"), headers: authHeader
        (accessToken));
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
        await sendNotification(accessToken: accessToken, title: "Your Social Media Post taken down", body: "Your post removed because it is marked as inappropriate", userId: userId);
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
setState(() => myName = pref.getString("name") ?? "");    await readDisabledPostList(accessToken: accessToken);
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
            pageName: "Social Media Posts",
            context: context,
            header: "Social Media Posts Moderation",
            child: dataTableContainer(
                primaryButtonOnTap: () => routeBack(context),
                primaryButtonText: "Active Posts",
                entryCount: postList.length,
                headerRow: ["Time Log", "Photo", "Post", "Status", "Actions"],
                flex: [2, 3, 2, 2, 1],
                title: "All Disabled Posts",
                showPlusButton: false,
                child: (postList.isEmpty)
                    ? const Center(child: NoData())
                    : ListView.builder(
                        itemCount: postList.length,
                        itemBuilder: (context, index) => dataTableAlternativeColorCells(index: index, children: [
                              dataTableListTile(
                                  flex: 2,
                                  title: 'Removed on: ${postList[index]["deletedAt"].toString().split("T")[0]}',
                                  subtitle: 'Posted on: ${postList[index]["createdAt"].toString().split("T")[0]}',
                                  hideImage: true),
                              dataTableNetworkImagesForSocialMedia(flex: 3, images: postList[index]["photos"] ?? []),
                              dataTableSingleInfo(flex: 2, title: postList[index]["content"]),
                              dataTableChip(flex: 2, label: "Disabled", color: Colors.redAccent),
                              dataTableIcon(
                                  toolTip: "Enable Post",
                                  onTap: () async => await showPrompt(
                                      context: context,
                                      onTap: () async {
                                        routeBack(context);
                                        await reActivePost(accessToken: accessToken, postId: postList[index]["postId"], userId: postList[index]["postedById"]);
                                      }),
                                  icon: Icons.visibility_outlined,
                                  color: Colors.green)
                            ])))));
  }
}
