import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:paysync/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaySync',
      home: Scaffold(
        appBar: AppBar(title: Text('PaySync Home')),
        body: Center(child: Text('Firebase Initialized!')),
      ),
    );
  }
}

class AuthTestPage extends StatefulWidget {
  @override
  _AuthTestPageState createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String verificationId = "";
  String? firebaseToken;
  String responseMessage = "";

  final String backendUrl =
      "http://your-server-ip:8080/auth"; // Replace with actual backend URL

  // Step 1: Send OTP
  void sendOtp() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        getToken();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          responseMessage = "OTP Verification Failed: ${e.message}";
        });
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {},
    );
  }

  // Step 2: Verify OTP
  void verifyOtp() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );
      await _auth.signInWithCredential(credential);
      getToken();
    } catch (e) {
      setState(() {
        responseMessage = "Invalid OTP";
      });
    }
  }

  // Step 3: Get Firebase Token
  void getToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      setState(() {
        firebaseToken = token;
      });
    }
  }

  // Step 4: Test Backend `/auth/login` API
  void testLoginApi() async {
    if (firebaseToken == null) return;

    final response = await http.post(
      Uri.parse("$backendUrl/login"),
      headers: {"Authorization": "Bearer $firebaseToken"},
    );

    setState(() {
      responseMessage = "Login API Response: ${response.body}";
    });
  }

  // Step 5: Test Backend `/auth/verifyToken` API
  void testVerifyTokenApi() async {
    if (firebaseToken == null) return;

    final response = await http.post(
      Uri.parse("$backendUrl/verifyToken"),
      headers: {"Authorization": "Bearer $firebaseToken"},
    );

    setState(() {
      responseMessage = "Verify Token API Response: ${response.body}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Auth Test Page")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: "Phone Number (+91...)"),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: sendOtp, child: Text("Send OTP")),
            TextField(
              controller: otpController,
              decoration: InputDecoration(labelText: "Enter OTP"),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: verifyOtp, child: Text("Verify OTP")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: testLoginApi,
              child: Text("Test Login API"),
            ),
            ElevatedButton(
              onPressed: testVerifyTokenApi,
              child: Text("Test Verify Token API"),
            ),
            SizedBox(height: 20),
            Text(
              "Firebase Token: ${firebaseToken ?? 'Not generated'}",
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 10),
            Text(
              "Response: $responseMessage",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
