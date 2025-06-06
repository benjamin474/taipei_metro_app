import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taipei_metro_app/account/signup_page.dart';
import '../../navigation_page.dart'; // 導覽頁面
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../unuseData/utils/csv_storage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final favKey = dotenv.env['FAVQS_API_KEY']!;
  bool isLoading = false;

  Future<void> signIn() async {
    try {
      setState(() => isLoading = true);
      final url = Uri.parse('https://favqs.com/api/session');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token token="$favKey"',
        },
        body: jsonEncode({
          'user': {
            'login': loginController.text,

            'password': passwordController.text,
          },
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error_code')) {
          // 登入失敗，顯示錯誤訊息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登入失敗: ${data['message']}')),
          );
        } else {
          // 登入成功，取得 token
          final userToken = data['User-Token'];
          // 儲存使用者帳號到 CSV
          await CsvStorage.saveData(loginController.text, '', []);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NavigationPage(
                userToken: userToken,
                userAccount: loginController.text, // Pass the user account
              ),
            ),
          );
        }
      } else {
        // 非預期的 HTTP 回應
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登入失敗: HTTP ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('發生錯誤: $e')));
    }
  }

  Future<void> forgotPassword() async {
    final email = loginController.text;
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入電子郵件以重設密碼')));
      return;
    }

    final url = Uri.parse('https://favqs.com/api/users/forgot_password');
    final response = await http.post(
      url,
      headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token token="$favKey"',
        },
      body: jsonEncode({
        'user': {'email': email},
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('重設連結已發送至您的電子郵件')));
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重設密碼失敗: ${error['message']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登入')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: loginController,
                      decoration: const InputDecoration(
                        labelText: '帳號或電子郵件',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: '密碼',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : signIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('登入', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: forgotPassword,
                      child: const Text('忘記密碼？',
                          style: TextStyle(color: Colors.blueAccent)),
                    ),
                    const Divider(height: 32, thickness: 1),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      },
                      child: const Text('註冊新帳號',
                          style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
