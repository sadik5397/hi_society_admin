import 'package:flutter/material.dart';
import 'package:hi_society_admin/main.dart';

class BuildingUtilityContacts extends StatefulWidget {
  const BuildingUtilityContacts({Key? key}) : super(key: key);

  @override
  State<BuildingUtilityContacts> createState() => _BuildingUtilityContactsState();
}

class _BuildingUtilityContactsState extends State<BuildingUtilityContacts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: includeDashboard(context: context, header: "Utility Contacts of ___", child: FlutterLogo()), //todo:
    );
  }
}
