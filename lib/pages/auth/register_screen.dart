import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktar_project/providers/providers.dart';
import 'package:toktar_project/utils/helpers/snackbar_helper.dart';
import '../../core/mixins/focus_node_mixin.dart';

class RegisterPage extends StatefulWidget with FocusNodeMixin {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  // Text Controllers
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Validator
  final _formKey = GlobalKey<FormState>();

  late FocusNode emailFocusNode;
  late FocusNode fullNameFocusNode;
  late FocusNode passwordFocusNode;
  late FocusNode confirmPasswordFocusNode;

  @override
  void initState() {
    super.initState();
    emailFocusNode = FocusNode();
    fullNameFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    confirmPasswordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    emailFocusNode.dispose();
    fullNameFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Icon(
                  Icons.phone_iphone_outlined,
                  size: 100,
                ),
                const SizedBox(
                  height: 20,
                ),
                Text('HELLO FRESH!',
                    ),
                const SizedBox(
                  height: 15,
                ),
                Text('Welcome to our app, newbie!',
                   ),
                const SizedBox(
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    // Email TextFormField
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        focusNode: emailFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          widget.fieldFocusChange(
                              context, emailFocusNode, fullNameFocusNode);
                        },
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: InputBorder.none,
                        ),
                        validator: (email) {
                          if (email != null &&
                              !EmailValidator.validate(email)) {
                            return "Enter a valid email!";
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    // Full Name TextFormField
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextFormField(
                        keyboardType: TextInputType.text,
                        controller: fullNameController,
                        focusNode: fullNameFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          widget.fieldFocusChange(
                              context, fullNameFocusNode, passwordFocusNode);
                        },
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          border: InputBorder.none,
                        ),
                        validator: (fullName) {
                          final namePattern =
                          RegExp(r'^[A-Z][a-z]+\s[A-Z][a-z]+$');
                          if (fullName == null || fullName.isEmpty) {
                            return 'Please enter your full name';
                          } else if (!namePattern.hasMatch(fullName.trim())) {
                            return 'Please enter a valid full name like "Toktar Sultan"';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    // New Password TextFormField
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          widget.fieldFocusChange(context, passwordFocusNode,
                              confirmPasswordFocusNode);
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'New Password',
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value != null && value.length < 8) {
                            return "Password must be 8 chars";
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    // Confirm Password TextFormField
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: true,
                        controller: confirmPasswordController,
                        focusNode: confirmPasswordFocusNode,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          confirmPasswordFocusNode.unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value != null &&
                              (confirmPasswordController.text !=
                                  passwordController.text)) {
                            return "Passwords must match!";
                          } else if (passwordController.text == "") {
                            return "Passwords must match!";
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.purple[800],
                  ),
                  child: TextButton(
                    onPressed: () {
                      confirmPasswordFocusNode.unfocus();
                      final isValidForm = _formKey.currentState!.validate();
                      if (isValidForm) {
                        context.read<AuthenticationProvider>().signUpUser(emailController.text, passwordController.text, confirmPasswordController.text, fullNameController.text, context);
                      }
                    },
                    child: Text('Sign Up',
                        style: TextStyle(
                            color: Colors.white, fontSize: 20
                        )),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Are you a member? ',
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/LoginScreen');
                      },
                      child: Text('Sign in',
                          style: TextStyle(
                              fontSize: 16, color: Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 10,),
                Center(child: GestureDetector(
                    child: SizedBox(
                        height: 70,
                        width: 70,
                        child: Image.asset('assets/images/googlephoto.png')),
                    onTap: () async {
                      context.read<AuthenticationProvider>().signInWithGoogle(context);

                    },
                )),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
