import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'sign_in.dart';

//Main
//region
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) print("---- HI SOCIETY | ADMIN DASHBOARD ----");
  final pref = await SharedPreferences.getInstance();
  final String? accessTokenFromSharedPreferences = pref.getString("accessToken");
  if (kDebugMode) print("Access Token from Android Local Shared Preference Status: $accessTokenFromSharedPreferences");
  runApp(MyApp(accessToken: accessTokenFromSharedPreferences ?? ""));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.accessToken}) : super(key: key);
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Hi Society Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            brightness: Brightness.light,
            appBarTheme: AppBarTheme(backgroundColor: Colors.blue.shade50, centerTitle: true)),
        home: accessToken.isEmpty ? const SignIn() : const Home());
  }
}
//endregion

//Static Values
//region
String placeholderImage = "https://media.istockphoto.com/vectors/thumbnail-image-vector-graphic-vector-id1147544807?k=20&m=1147544807&s=612x612&w=0&h=pBhz1dkwsCMq37Udtp9sfxbjaMl27JUapoyYpQm0anc=";
Color themeOf = const Color(0xFFe8f5ff);
Color primaryColor = Colors.blue;
//endregion

//Components
//region
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

Future<dynamic> route(BuildContext context, Widget widget) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => widget),
  );
}

dynamic routeBack(BuildContext context) {
  return Navigator.pop(context);
}

showSnackBar({required BuildContext context, String action = "Dismiss", required String label, int seconds = 2, int milliseconds = 0}) {
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
                // fillColor: themeOf,
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

Widget primaryButton({double width = double.maxFinite, required String title, required VoidCallback onTap, bool primary = true}) {
  return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
      child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: primary ? primaryColor : themeOf,
              fixedSize: Size(width, 44),
              foregroundColor: primary ? Colors.white : primaryColor,
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.transparent), borderRadius: BorderRadius.circular(12))),
          child: Text(title.toUpperCase())));
}

ListTile basicListTile({required BuildContext context, required String title, required String subTitle, VoidCallback? onTap}) {
  return ListTile(
      visualDensity: VisualDensity.standard,
      tileColor: Colors.grey.shade50,
      enableFeedback: true,
      dense: false,
      trailing: IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded), onPressed: onTap, color: Colors.grey),
      title: Text(title),
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

//endregion
