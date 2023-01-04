import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:hi_society_admin/views/amenities/amenity_category.dart';
import 'package:hi_society_admin/views/home.dart';
import 'package:hi_society_admin/views/rent_sell_ads/rent_sell_ads.dart';
import 'package:hi_society_admin/views/users/users.dart';
import 'package:page_transition/page_transition.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/all_buildings/all_buildings.dart';
import 'views/security_alerts/security_alert.dart';
import 'views/sign_in.dart';
import 'views/utility_contacts/utility_contact_category.dart';

//region Static Values
String placeholderImage = "https://i.ibb.co/NSDmSZ0/Sqr-hi-Society-Placeholder.png";
Color themeOf = const Color(0xFFe6f5ff);
Color primaryColor = const Color(0xff0392f7);
//endregion

//region Static Functions
String capitalizeAllWord(String value) {
  var result = value[0].toUpperCase();
  for (int i = 1; i < value.length; i++) {
    (value[i - 1] == " ") ? result = result + value[i].toUpperCase() : result = result + value[i];
  }
  return result;
}
//endregion

//region Components
AppBar primaryAppBar({required BuildContext context, String? title}) {
  return AppBar(title: Text(title ?? "Hi Society"), actions: [
    IconButton(
        onPressed: () async {
          final pref = await SharedPreferences.getInstance();
          await pref.clear();
          // ignore: use_build_context_synchronously
          route(context, const SignIn());
        },
        icon: const Icon(Icons.more_vert_rounded))
  ]);
}

Container dashboardHeader({required BuildContext context, String? title}) {
  return Container(
      padding: const EdgeInsets.all(12),
      height: 84,
      alignment: Alignment.center,
      color: Colors.white,
      width: double.maxFinite,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SelectableText(title.toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black.withOpacity(.75))),
          SelectableText("Logged in as Super-Admin", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black.withOpacity(.75))),
        ]),
        IconButton(
            onPressed: () {
              showPrompt(
                  context: context,
                  label: "You Will Be Logged Out",
                  onTap: () async {
                    route(context, const SignIn());
                    final pref = await SharedPreferences.getInstance();
                    pref.clear();
                  });
            },
            icon: const Icon(Icons.power_settings_new_rounded),
            tooltip: "Sign Out")
      ]));
}

Future<dynamic> route(BuildContext context, Widget widget) => Navigator.push(context, PageTransition(child: widget, type: PageTransitionType.fade));

dynamic routeBack(BuildContext context) => Navigator.pop(context);

showSnackBar({required BuildContext context, String action = "Dismiss", required String label, int seconds = 0, int milliseconds = 100}) {
  final snackBar = SnackBar(
    backgroundColor: primaryColor,
    dismissDirection: DismissDirection.horizontal,
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: seconds, milliseconds: milliseconds),
    content: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
    action: SnackBarAction(textColor: Colors.white, label: action, onPressed: () => ScaffoldMessenger.of(context).clearSnackBars()),
  );
  return ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

showError({required BuildContext context, String action = "OKAY", String? label, String? title, int? seconds}) {
  return QuickAlert.show(
      context: context,
      width: 400,
      type: QuickAlertType.error,
      borderRadius: 16,
      animType: QuickAlertAnimType.slideInUp,
      title: title ?? 'ERROR',
      text: capitalizeAllWord(label ?? "Something Went Wrong!"),
      confirmBtnText: action,
      backgroundColor: Colors.white,
      titleColor: primaryColor,
      textColor: Colors.black87,
      autoCloseDuration: seconds != null ? Duration(seconds: seconds) : null);
}

showSuccess({required BuildContext context, String action = "OKAY", String? label, String? title, int? seconds, VoidCallback? onTap}) {
  return QuickAlert.show(
      context: context,
      onConfirmBtnTap: onTap,
      width: 400,
      type: QuickAlertType.success,
      borderRadius: 16,
      animType: QuickAlertAnimType.slideInUp,
      title: title ?? 'SUCCESS',
      text: capitalizeAllWord(label ?? "Progress Complete"),
      confirmBtnText: action,
      backgroundColor: Colors.white,
      titleColor: primaryColor,
      textColor: Colors.black87,
      autoCloseDuration: seconds != null ? Duration(seconds: seconds) : null);
}

showPrompt({required BuildContext context, String action = "YES", String cancel = "NO", String? label, String? title, int? seconds, VoidCallback? onTap}) {
  return QuickAlert.show(
      context: context,
      onConfirmBtnTap: onTap,
      onCancelBtnTap: () => routeBack(context),
      width: 400,
      type: QuickAlertType.warning,
      borderRadius: 16,
      animType: QuickAlertAnimType.slideInUp,
      title: title ?? 'Are You Sure?',
      text: capitalizeAllWord(label ?? "Click Yes/No"),
      confirmBtnText: action,
      showCancelBtn: true,
      cancelBtnText: cancel,
      backgroundColor: Colors.white,
      titleColor: primaryColor,
      textColor: Colors.black87,
      autoCloseDuration: seconds != null ? Duration(seconds: seconds) : null);
}

InkWell menuGridTile({required String title, required String assetImage, Widget? toPage, required BuildContext context}) {
  return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => (toPage == null) ? showSnackBar(context: context, label: "Not Implemented Yet") : route(context, toPage),
      child: Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x1E1ABC9C)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Image.asset(
                  "assets/$assetImage.png",
                  height: 40,
                  fit: BoxFit.fitHeight,
                )),
            Text(title, textAlign: TextAlign.center)
          ])));
}

Padding primaryTextField(
    {required String labelText,
    double? width,
    bool isPassword = false,
    double? bottomPadding,
    bool isDate = false,
    bool hasSubmitButton = false,
    TextInputType keyboardType = TextInputType.text,
    String hintText = "Type Here",
    required TextEditingController controller,
    bool autoFocus = false,
    FocusNode? focusNode,
    Color? fillColor,
    String errorText = "This field should not be empty",
    bool required = false,
    String autofillHints = "",
    bool showPassword = false,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    VoidCallback? showPasswordPressed,
    VoidCallback? onFieldSubmittedAlternate,
    Function(String value)? onFieldSubmitted,
    String? initialValue,
    bool isDisable = false}) {
  return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding ?? 18),
      child: SizedBox(
        width: width,
        child: TextFormField(
            initialValue: initialValue,
            autofillHints: [autofillHints],
            focusNode: focusNode,
            onFieldSubmitted: onFieldSubmitted,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: (isPassword) ? !showPassword : false,
            controller: controller,
            // style: textFieldLabel,
            autofocus: autoFocus,
            enabled: !isDisable,
            validator: (value) => required
                ? value == null || value.isEmpty
                    ? errorText
                    : null
                : null,
            decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                labelText: labelText,
                isDense: false,
                alignLabelWithHint: true,
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.all(12),
                // labelStyle: textFieldLabel,
                hintText: hintText,
                // hintStyle: textFieldHint,
                // floatingLabelStyle: textFieldLabelFloating,
                suffixIcon: (isPassword)
                    ? IconButton(
                        onPressed: showPasswordPressed,
                        icon: Icon((!showPassword) ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        iconSize: 18,
                        color: Colors.grey.shade500,
                      )
                    : (isDate)
                        ? IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.calendar_month_sharp),
                            iconSize: 18,
                            color: Colors.grey.shade500,
                          )
                        : (hasSubmitButton)
                            ? IconButton(
                                onPressed: onFieldSubmittedAlternate,
                                icon: const Icon(Icons.arrow_downward_sharp),
                                iconSize: 18,
                                color: Colors.grey.shade500,
                              )
                            : (true) //todo: controller.text.isNotEmpty (state is not updating)
                                ? IconButton(
                                    onPressed: () => controller.clear(),
                                    icon: const Icon(Icons.cancel_outlined),
                                    iconSize: 18,
                                    color: Colors.grey.shade500,
                                  )
                                // ignore: dead_code
                                : null)),
      ));
}

Padding primaryDropdown(
    {double? width, double? paddingLeft, double? paddingRight, required String title, required List<String> options, required dynamic value, required void Function(Object? value) onChanged}) {
  return Padding(
      padding: EdgeInsets.fromLTRB(paddingLeft ?? 12, 0, paddingRight ?? 12, 12 * 1.5),
      child: DropdownButton2(
        underline: const SizedBox(),
        iconEnabledColor: Colors.black.withOpacity(.5),
        buttonElevation: 0,
        dropdownElevation: 1,
        selectedItemHighlightColor: themeOf,
        isExpanded: true,
        enableFeedback: true,
        buttonPadding: const EdgeInsets.only(left: 12, right: 12),
        buttonDecoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: themeOf),
        dropdownPadding: EdgeInsets.zero,
        dropdownDecoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
        hint: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
        items: options.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)))).toList(),
        selectedItemBuilder: (context) => List.generate(options.length, (index) => Align(alignment: const Alignment(-1, 0), child: Text("$title: ${options[index]}"))),
        value: value,
        onChanged: onChanged,
        buttonWidth: width ?? double.maxFinite,
      ));
}

Widget primaryButton(
    {double paddingTop = 0,
    double paddingLeft = 12,
    double paddingRight = 12,
    double paddingBottom = 12,
    double width = double.maxFinite,
    required String title,
    IconData? icon,
    required VoidCallback onTap,
    bool primary = true}) {
  return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(paddingLeft, paddingTop, paddingRight, paddingBottom),
      child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: primary ? primaryColor : themeOf,
              fixedSize: Size(width, 44),
              foregroundColor: primary ? Colors.white : primaryColor,
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent), borderRadius: BorderRadius.circular(12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [if (icon != null) Icon(icon, size: 18), if (icon != null) const SizedBox(width: 6), Text(title.toUpperCase())],
          )));
}

ListTile basicListTile({required BuildContext context, required String title, required String subTitle, VoidCallback? onTap, bool isVerified = false}) {
  return ListTile(
      visualDensity: VisualDensity.standard,
      tileColor: Colors.grey.shade50,
      enableFeedback: true,
      dense: false,
      trailing: isVerified ? CircleAvatar(backgroundColor: primaryColor, child: const Icon(Icons.download_done_rounded, color: Colors.white)) : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
      title: Text(title, style: TextStyle(color: isVerified ? primaryColor : Colors.black87)),
      subtitle: Text(subTitle),
      onTap: onTap);
}

ListTile smartListTile({required BuildContext context, required String title, String? subTitle, VoidCallback? onEdit, VoidCallback? onDelete, VoidCallback? onTap}) {
  return ListTile(
      visualDensity: VisualDensity.comfortable,
      tileColor: Colors.grey.shade50,
      enableFeedback: true,
      dense: false,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(12), child: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete, color: Colors.redAccent, iconSize: 24, visualDensity: VisualDensity.comfortable)),
        Padding(padding: const EdgeInsets.all(12), child: IconButton(icon: const Icon(Icons.edit), onPressed: onEdit, color: primaryColor, iconSize: 24, visualDensity: VisualDensity.comfortable))
      ]),
      title: Text(title),
      subtitle: subTitle != null ? Text(subTitle) : null,
      onTap: onTap);
}

Padding sidebarMenuItem({String pageName = "", required BuildContext context, Widget? toPage, IconData icon = Icons.chevron_right, required String label, bool isHeader = false, bool isSubMenu = false}) {
  return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: isHeader
          ? Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 20))
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.standard,
                  shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: pageName.toLowerCase() == label.toLowerCase() ? Colors.white.withOpacity(.15) : Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  fixedSize: const Size(256, 50)),
              onPressed: () => route(context, toPage ?? const AllBuildings()),
              child: Padding(
                padding: EdgeInsets.only(left: isSubMenu ? 36 : 0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 20)), Icon(icon)]),
              )));
}

Theme sidebarMenuHead({required BuildContext context, required String title, required List<Widget> children}) {
  return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
          initiallyExpanded: true,
          maintainState: true,
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 28),
          title: sidebarMenuItem(context: context, label: title, isHeader: true),
          children: children));
}

Row includeDashboard({bool isScrollablePage = false, required Widget child, required BuildContext context, String? header, required String pageName}) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
        width: 280,
        color: primaryColor,
        child: Column(children: [
          InkWell(
              onTap: () {
                route(context, const AllBuildings());
              },
              child: Container(padding: const EdgeInsets.all(24), height: 84, width: 280, color: Colors.blueAccent, child: Image.asset("assets/logo.png", fit: BoxFit.fitHeight))),
          const SizedBox(height: 6),
          sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "All Buildings", toPage: const AllBuildings()),
          sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Users", toPage: const Users()),
          sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Rent/Sell Ads", toPage: const RentSellAds()),
          sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Social Media Posts", toPage: const Home()),
          sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Utility Contacts", toPage: const UtilityContactCategory()),
          // sidebarMenuHead(context: context, title: "Utility Contacts", children: [
          //   sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Contact Group", toPage: const UtilityContactSubGroup(), isSubMenu: true),
          //   sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Contacts", toPage: const UtilityContacts(), isSubMenu: true),
          // ]),
          sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Amenities", toPage: const AmenityCategory()),
          sidebarMenuItem(pageName: pageName, context: context, icon: Icons.chevron_right, label: "Security Alerts", toPage: const SecurityAlertGroup()),
        ])),
    Expanded(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [dashboardHeader(context: context, title: header), Expanded(child: isScrollablePage ? SingleChildScrollView(child: child) : child)]))
  ]);
}

//endregion

//region DataTable Components
Container dataTableContainer(
    {required String title,
    required Widget child,
    double paddingBottom = 12,
    double headerPadding = 16,
    bool isScrollableWidget = true,
    int entryCount = 0,
    String primaryButtonText = "Add New",
    VoidCallback? primaryButtonOnTap,
    String secondaryButtonText = "Add New",
    List<String> headerRow = const [],
    List<int> flex = const [],
    VoidCallback? secondaryButtonOnTap}) {
  return Container(
      margin: const EdgeInsets.all(12).copyWith(bottom: paddingBottom),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              SelectableText(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              if (entryCount > 0)
                Chip(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    backgroundColor: Colors.black.withOpacity(.05),
                    label: SelectableText("$entryCount Entries", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal))),
              const Expanded(child: SizedBox()),
              if (primaryButtonOnTap != null)
                primaryButton(title: primaryButtonText, onTap: primaryButtonOnTap, width: 160, paddingBottom: 0, paddingRight: 0, icon: primaryButtonText == "Edit" ? Icons.edit : Icons.add),
              if (secondaryButtonOnTap != null) primaryButton(title: secondaryButtonText, onTap: secondaryButtonOnTap, width: 160, paddingBottom: 0, paddingRight: 0, icon: Icons.add)
            ])),
        const Divider(height: 1),
        Padding(
            padding: EdgeInsets.all(headerPadding),
            child: Row(
                children: List.generate(
                    headerRow.length,
                    (index) => Expanded(
                        flex: flex[index],
                        child: SelectableText(headerRow[index], textAlign: index == 0 ? TextAlign.start : TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))))),
        isScrollableWidget ? Expanded(child: child) : child
      ]));
}

ColoredBox dataTableAlternativeColorCells({required int index, required List<Widget> children}) =>
    ColoredBox(color: index % 2 == 0 ? themeOf.withOpacity(.4) : Colors.transparent, child: Row(children: children));

Expanded dataTableListTile({required String title, String? subtitle, int flex = 1, bool hideImage = false, String? img}) {
  return Expanded(
      flex: flex,
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            if (!hideImage) CircleAvatar(backgroundImage: NetworkImage(img ?? placeholderImage), radius: 24, backgroundColor: Colors.grey.shade50),
            if (!hideImage) const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                SelectableText(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (subtitle != null) const SizedBox(height: 3),
                if (subtitle != null) SelectableText(subtitle, style: const TextStyle(color: Colors.black87))
              ]),
            )
          ])));
}

Expanded dataTableSingleInfo({required String title, int flex = 1, Color color = Colors.black87, TextAlign alignment = TextAlign.center}) {
  return Expanded(flex: flex, child: SelectableText(title, textAlign: alignment, style: TextStyle(color: color, fontWeight: FontWeight.normal, fontSize: 16, height: 1.5)));
}

Expanded dataTableChip({required String label, Color color = const Color(0xff2196f3), int flex = 1, Alignment alignment = Alignment.center}) {
  return Expanded(
      flex: flex,
      child: Align(
          alignment: alignment,
          child: Chip(
              label: SelectableText(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14, height: 0)),
              backgroundColor: color.withOpacity(.08),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding: const EdgeInsets.only(right: 14),
              avatar: CircleAvatar(backgroundColor: color, radius: 4))));
}

Expanded dataTableIcon({required VoidCallback onTap, int flex = 1, required IconData icon, Color color = const Color(0xff2196f3), String toolTip = "Edit"}) {
  return Expanded(
      flex: flex,
      child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: IconButton(
              style: ElevatedButton.styleFrom(shape: const CircleBorder()),
              onPressed: onTap,
              icon: Icon(icon, color: color),
              visualDensity: VisualDensity.standard,
              iconSize: 28,
              tooltip: toolTip.toUpperCase(),
              padding: const EdgeInsets.all(16))));
}

Expanded dataTableNull({int flex = 1}) => Expanded(flex: flex, child: const SizedBox());

Padding photoUploaderPro({required VoidCallback onTap, required String base64img, double? width, double? height, String networkImage = ""}) {
  return Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Material(
        color: themeOf,
        borderRadius: BorderRadius.circular(16) / 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16) / 2,
          child: AnimatedContainer(
              width: width ?? 100,
              height: height ?? 100,
              duration: const Duration(milliseconds: 500),
              padding: (base64img == "") ? const EdgeInsets.all(12 * 1.5) : EdgeInsets.zero,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16) / 2),
              child: (networkImage != "" && base64img == "")
                  ? Image.network(networkImage, fit: BoxFit.cover)
                  : (base64img == "")
                      ? DottedBorder(
                          dashPattern: const [3, 6],
                          color: Colors.black26,
                          strokeWidth: 1,
                          child: Container(height: (height ?? 100) - 18, width: (width ?? 100) - 18, alignment: Alignment.center, child: const Icon(Icons.camera_alt_outlined, color: Colors.black26, size: 32)))
                      : Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16) / 2),
                          child: ClipRRect(borderRadius: BorderRadius.circular(16) / 2, child: Image.memory(base64Decode(base64img), fit: BoxFit.cover)))),
        )),
  );
}
//endregion
