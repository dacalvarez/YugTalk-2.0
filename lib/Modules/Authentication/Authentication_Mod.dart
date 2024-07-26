import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yugtalk/Modules/Authentication/Verification_Widget.dart';
import 'package:yugtalk/Modules/Authentication/ForgotPassword_Widget.dart';
import '../../Screens/Home_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Authentication_Mod extends StatefulWidget {
  const Authentication_Mod({Key? key});

  @override
  _Authentication_ModState createState() => _Authentication_ModState();
}

class _Authentication_ModState extends State<Authentication_Mod>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Welcome to YugTalk!',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              tabs: [
                Tab(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _tabController.animateTo(0);
                    },
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Tab(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _tabController.animateTo(1);
                    },
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Register',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.deepPurple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            LoginWidget(onContinue: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const Home_Mod(),
                  settings: const RouteSettings(name: Home_Mod.routeName),
                ),
              );
            }),
            RegisterWidget(onRegistered: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Verification_Widget(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class LoginWidget extends StatefulWidget {
  final Function onContinue;

  const LoginWidget({Key? key, required this.onContinue}) : super(key: key);

  @override
  _LoginWidgetState createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  bool _isLoading = false;
  bool _obscureText = true;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signInWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection.'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null && user.emailVerified) {
        widget.onContinue();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified or user does not exist.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in: $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/welcomeLogin.png',
                height: 250,
                width: 250,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscureText,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : FloatingActionButton.extended(
                              onPressed: () {
                                String email = emailController.text.trim();
                                String password =
                                    passwordController.text.trim();
                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please fill in all the fields.'),
                                    ),
                                  );
                                } else {
                                  signInWithEmailAndPassword(
                                      context, email, password);
                                }
                              },
                              backgroundColor: const Color(0xFFe8c221),
                              label: const Text('Continue'),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPassword_Widget(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterWidget extends StatefulWidget {
  final Function onRegistered;

  const RegisterWidget({Key? key, required this.onRegistered})
      : super(key: key);

  @override
  _RegisterWidgetState createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isReenterPasswordVisible = false;
  bool _termsAccepted = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController guardianNameController = TextEditingController();
  final TextEditingController guardianNoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController reenterPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    Future<void> _registerUser(BuildContext context) async {
      try {
        setState(() {
          _isLoading = true;
        });

        final String fullName = nameController.text.trim();
        final int age = int.tryParse(ageController.text.trim()) ?? 0;
        final String guardianName = guardianNameController.text.trim();
        final String guardianNo = guardianNoController.text.trim();
        final String email = emailController.text.trim();
        final String password = passwordController.text.trim();

        final String reenteredPassword = reenterPasswordController.text.trim();
        if (password != reenteredPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Passwords don't match")),
          );
          return;
        }

        if (fullName.isEmpty ||
            age == 0 ||
            guardianName.isEmpty ||
            guardianNo.isEmpty ||
            email.isEmpty ||
            password.isEmpty ||
            reenteredPassword.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill in all fields")),
          );
          return;
        }

        if (!_termsAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Please accept the Terms and Conditions")),
          );
          return;
        }

        final QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await FirebaseFirestore.instance.collection('user').get();

        int highestId = 0;
        for (final doc in querySnapshot.docs) {
          final int docId = int.tryParse(doc.id) ?? 0;
          if (docId > highestId) {
            highestId = docId;
          }
        }

        final String userId = (highestId + 1).toString();

        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance.collection('user').doc(userId).set({
          'fullName': fullName,
          'age': age,
          'guardianName': guardianName,
          'guardianNo': guardianNo,
          'email': email,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully')),
        );

        widget.onRegistered();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering user: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    void _showTermsDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Terms and Conditions'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Welcome to YugTalk, ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'an Augmentative and Alternative Communication (AAC) app designed to aid pediatric patients aged 3-5 with speech and language disorders, while facilitating assessments and therapeutic sessions. By using this app, you agree to be bound by the following terms and conditions:\n\n',
                        ),
                        TextSpan(
                          text: 'Purpose of the App:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'YugTalk serves as an AAC tool to assist children diagnosed with speech and language disorders, including apraxia of speech, phonological disorders, and receptive-expressive language disorder. The app facilitates communication using symbols and images in both Filipino and English languages. It also supports guardians in guiding children and allows Speech-Language Pathologists (SLPs) to perform standard assessments such as modified Preschool Language Scale, Fifth Edition (PLS-5) or Brigance.\n\n',
                        ),
                        TextSpan(
                          text: 'Responsibility:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'It is the responsibility of parents or legal guardians to supervise and monitor the use of YugTalk by children aged 3-5. This includes ensuring appropriate usage and providing necessary support during app interactions. Guardians are expected to follow the guidance provided by the research team and SLPs regarding the safe and effective use of the app.\n\n',
                        ),
                        TextSpan(
                          text: 'Privacy and Data Security:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'We prioritize the privacy and security of user data. Personal information collected through YugTalk will only be used for improving app functionality and research purposes. All data collected will be anonymized and aggregated before any potential publication or sharing, and will not be shared with third parties without consent, except as required by law.\n\n',
                        ),
                        TextSpan(
                          text: 'In-App Content:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'All images, symbols, and educational content provided within YugTalk are curated to be suitable for young children with speech disorders. Guardians are advised to monitor the use of the app and report any inappropriate content immediately for prompt action.\n\n',
                        ),
                        TextSpan(
                          text: 'User Conduct:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'Users agree to use YugTalk in a manner that is consistent with its intended purpose and refrain from engaging in activities that may disrupt or harm the app\'s functionality or other users\' experience. Misuse or unauthorized access to the app may result in the suspension or termination of user privileges.\n\n',
                        ),
                        TextSpan(
                          text: 'Installation and Updates:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'YugTalk will be sideloaded onto iPads provided by the research team. Parents or legal guardians acknowledge that the app will be installed for research purposes and agree to allow their child to use YugTalk under supervision. Periodic updates and maintenance may be performed by the research team to enhance YugTalk\'s performance and add new features. Users are encouraged to follow guidance from the research team regarding app updates.\n\n',
                        ),
                        TextSpan(
                          text: 'Feedback and Support:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'We welcome feedback and suggestions from users and strive to provide timely support for any technical issues encountered while using YugTalk. Please contact our support team for assistance.\n\n',
                        ),
                        TextSpan(
                          text: 'Research Participation:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'YugTalk may involve research activities aimed at developing and improving AAC technologies. Participation in research is voluntary, and parental consent is required before children can participate in any research-related activities. Guardians have the right to withdraw their consent at any time.\n\n',
                        ),
                        TextSpan(
                          text: 'Governing Law:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'These terms and conditions are governed by and construed in accordance with the laws of the Philippines. Any disputes arising out of or in connection with these terms and conditions shall be subject to the exclusive jurisdiction of the courts of the Philippines.\n\n',
                        ),
                        TextSpan(
                          text:
                              'By using YugTalk, you acknowledge that you have read, understood, and agree to abide by these terms and conditions.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _termsAccepted = true;
                  });
                },
              ),
            ],
          );
        },
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'New user?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name of User',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Age of User',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: guardianNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name of Guardian',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: guardianNoController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Guardian Contact Number',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reenterPasswordController,
                        obscureText: !_isReenterPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Re-enter Password',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isReenterPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: () {
                              setState(() {
                                _isReenterPasswordVisible =
                                    !_isReenterPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Checkbox(
                            value: _termsAccepted,
                            onChanged: (bool? value) {
                              setState(() {
                                _termsAccepted = value ?? false;
                              });
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              _showTermsDialog(context);
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'I accept the ',
                                style: TextStyle(color: Colors.black),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            _isLoading ? null : () => _registerUser(context),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xFFe8c221)),
                          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Register'),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
