// String baseUrl = "http://127.0.0.1:3000/api"; //Localhost
String baseUrl = "https://g01.fusionbdtech.com"; //TestServer
// String baseUrl = "http://194.163.40.107:4441"; //LiveServer
// String baseUrl = "http://127.0.0.1:3000"; //LocalhostAndroidEmulator
// String baseUrl = "http://10.0.2.2:3000"; //LocalhostAndroidEmulator

Map<String, String> primaryHeader = {"Access-Control-Allow-Headers": "X-Requested-With", 'Accept': '*/*', "Access-Control_Allow_Origin": "*", "Content-Type": "application/json", "charset": "utf-8"};

Map<String, String> authHeader(String accessToken) {
  return {
    "Access-Control-Allow-Headers": "X-Requested-With",
    'Accept': '*/*',
    "Access-Control_Allow_Origin": "*",
    "Content-Type": "application/json",
    "Authorization": "Bearer $accessToken",
    "charset": "utf-8"
  };
}

// to deploy release build web
// flutter build web --web-renderer html

//flutter run -d chrome --web-renderer html // to run the app
//flutter build web --web-renderer html --release // to generate a production build
