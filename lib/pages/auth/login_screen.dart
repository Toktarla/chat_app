import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktar_project/providers/providers.dart';
import '../../core/mixins/focus_node_mixin.dart';


class LoginPage extends StatefulWidget with FocusNodeMixin {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Focus Nodes
  late FocusNode emailFocusNode;
  late FocusNode passwordFocusNode;

  // Text Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Validator
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            autovalidateMode: AutovalidateMode.disabled,
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Icon(
                  Icons.phone_android,
                  size: 100,
                ),
                const SizedBox(
                  height: 75,
                ),
                Text('HELLO AGAIN!'),
                const SizedBox(
                  height: 15,
                ),
                Text('Welcome back , you have been missed',),
                const SizedBox(
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        focusNode: emailFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: InputBorder.none,
                        ),
                        onFieldSubmitted: (_){
                          widget.fieldFocusChange(context, emailFocusNode, passwordFocusNode);

                        },
                        validator: (email) {
                          if (email != null &&
                              !EmailValidator.validate(email)) {
                            return "It is not email!";
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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: true,
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Password',
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
                      final isValidForm = _formKey.currentState!.validate();
                      if (isValidForm) {
                        context.read<AuthenticationProvider>().signInUser(emailController.text, passwordController.text, context);
                      }
                    },
                    child: Text('Sign In',
                        style: TextStyle(
                            color: Colors.white, fontSize: 20)),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member? ',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context,'/RegisterScreen');
                      },
                      child: Text('Register now',
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
