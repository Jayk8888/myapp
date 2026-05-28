import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddConfessionScreen extends StatefulWidget {
  const AddConfessionScreen({super.key});

  @override
  State<AddConfessionScreen> createState() => _AddConfessionScreenState();
}

class _AddConfessionScreenState extends State<AddConfessionScreen> {
  final textController = TextEditingController();
  final confessionFocusNode = FocusNode();
  bool submitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      confessionFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    confessionFocusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  Future<void> submitConfession() async {
    final text = textController.text.trim();
    if (text.isEmpty || submitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      submitting = true;
      errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('confessions').add({
        'text': text,
        'likes': 0,
        'dislikes': 0,
        'authorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Prevent Flutter Web from trying to update a disposed input element.
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 10));

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Could not post confession. Please try again.';
        submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = textController.text.trim().isNotEmpty && !submitting;

    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080810),
        elevation: 0,
        titleSpacing: 24,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANONYMOUSLY SHARE YOUR SECRET',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF101018),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 30,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: textController,
                    focusNode: confessionFocusNode,
                    maxLines: null,
                    minLines: 10,
                    textAlignVertical: TextAlignVertical.top,
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your confession...',
                      hintStyle: GoogleFonts.dmSerifDisplay(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 24,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  errorMessage!,
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFf87171),
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 68,
                child: ElevatedButton(
                  onPressed: canSubmit ? submitConfession : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    submitting ? 'wait' : 'post',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
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
