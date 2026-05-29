import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrumlab_flutter_tindercard/scrumlab_flutter_tindercard.dart';

import '../models/confession.dart';
import 'add_confession_screen.dart';
import 'profile_screen.dart';

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperState();
}

class _WhisperState extends State<WhisperScreen> {
  final cardController = CardController();

  List<Confession> confessions = [];
  bool loading = true;
  bool actionInProgress = false;
  Offset singleCardOffset = Offset.zero;
  double singleCardTurns = 0;
  Offset _manualDrag = Offset.zero;
  bool _isDraggingManually = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadConfessions();
  }

  Future<void> loadConfessions() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final unseen = await fetchUnseenConfessions();

      if (!mounted) return;

      setState(() {
        confessions = unseen;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error: $error';
        loading = false;
      });
    }
  }

  Future<List<Confession>> fetchUnseenConfessions() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final interacted = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('interactions')
        .get();

    final seenIds = interacted.docs.map((doc) => doc.id).toSet();

    final snapshot = await FirebaseFirestore.instance
        .collection('confessions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .where((doc) => !seenIds.contains(doc.id))
        .map(Confession.fromFirestore)
        .toList();
  }

  Future<void> interactWithConfession(
    Confession confession,
    String type,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final interactionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('interactions')
        .doc(confession.id);

    final confessionRef = FirebaseFirestore.instance
        .collection('confessions')
        .doc(confession.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final interaction = await transaction.get(interactionRef);

      if (interaction.exists) return;

      transaction.set(interactionRef, {
        'type': type,
        'confessionId': confession.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(confessionRef, {
        type == 'like' ? 'likes' : 'dislikes': FieldValue.increment(1),
      });
    });
  }

  Future<void> handleSwipe(CardSwipeOrientation orientation, int index) async {
    if (orientation == CardSwipeOrientation.recover) return;
    if (index < 0 || index >= confessions.length) return;

    final confession = confessions[index];
    final type = orientation == CardSwipeOrientation.right ? 'like' : 'dislike';

    try {
      await interactWithConfession(confession, type);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error: $error';
      });
    }
  }

  Future<void> triggerSwipe(String type) async {
    if (actionInProgress || confessions.isEmpty) return;

    if (confessions.length == 1) {
      await triggerSingleCardSwipe(type);
      return;
    }

    if (type == 'like') {
      cardController.triggerRight();
    } else if (type == 'dislike') {
      cardController.triggerLeft();
    }
  }

  Future<void> triggerSingleCardSwipe(String type) async {
    final confession = confessions.first;
    final isLike = type == 'like';

    setState(() {
      actionInProgress = true;
      errorMessage = null;
      singleCardOffset = Offset(isLike ? 1.5 : -1.5, 0.08);
      singleCardTurns = isLike ? 0.06 : -0.06;
    });

    await Future.delayed(const Duration(milliseconds: 260));

    try {
      await interactWithConfession(confession, type);

      if (!mounted) return;

      setState(() {
        confessions = [];
        singleCardOffset = Offset.zero;
        singleCardTurns = 0;
        actionInProgress = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error: $error';
        singleCardOffset = Offset.zero;
        singleCardTurns = 0;
        actionInProgress = false;
      });
    }
  }

  Future<void> openAddConfessionScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddConfessionScreen()),
    );

    if (created == true) {
      await loadConfessions();
    }
  }

  void openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Widget buildConfessionCard(Confession confession) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: confession.color,
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      child: Stack(
        children: [
          Center(
            child: Text(
              confession.text,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                color: Colors.white,
                fontSize: 24,
                height: 1.6,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '❤ ${confession.likes}',
                  style: const TextStyle(color: Color(0xFF4ade80)),
                ),
                const SizedBox(width: 20),
                Text(
                  '✕ ${confession.dislikes}',
                  style: const TextStyle(color: Color(0xFFf87171)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    double size = 76,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: color.withValues(alpha: 0.45), width: 3),
          backgroundColor: color.withValues(alpha: 0.1),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }

  Widget buildActionButtons({bool onlyAddButton = false}) {
    final canAct = !actionInProgress && confessions.isNotEmpty;

    if (onlyAddButton) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildActionButton(
            icon: Icons.add,
            color: Colors.white38,
            onPressed: openAddConfessionScreen,
            size: 64,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildActionButton(
          icon: Icons.close,
          color: const Color(0xFFf87171),
          onPressed: canAct ? () => triggerSwipe('dislike') : null,
        ),
        const SizedBox(width: 34),
        buildActionButton(
          icon: Icons.add,
          color: Colors.white38,
          onPressed: openAddConfessionScreen,
          size: 64,
        ),
        const SizedBox(width: 34),
        buildActionButton(
          icon: Icons.favorite,
          color: const Color(0xFF4ade80),
          onPressed: canAct ? () => triggerSwipe('like') : null,
        ),
      ],
    );
  }

  Widget buildFeed() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: loadConfessions,
                child: const Text('retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (confessions.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "You're all out of confessions",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Come back later for more secrets.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          buildActionButtons(onlyAddButton: true),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: confessions.length == 1
                ? GestureDetector(
                    onPanUpdate: actionInProgress
                        ? null
                        : (d) => setState(() {
                              _isDraggingManually = true;
                              _manualDrag += d.delta;
                            }),
                    onPanEnd: actionInProgress
                        ? null
                        : (d) {
                            if (_manualDrag.dx.abs() > 80) {
                              final type = _manualDrag.dx > 0 ? 'like' : 'dislike';
                              setState(() {
                                _isDraggingManually = false;
                                _manualDrag = Offset.zero;
                              });
                              triggerSingleCardSwipe(type);
                            } else {
                              setState(() {
                                _isDraggingManually = false;
                                _manualDrag = Offset.zero;
                              });
                            }
                          },
                    child: _isDraggingManually
                        ? Transform(
                            transform: Matrix4.identity()
                              ..translateByDouble(
                                _manualDrag.dx,
                                _manualDrag.dy * 0.3,
                                0,
                                1,
                              )
                              ..rotateZ(_manualDrag.dx * 0.0007),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.58,
                              child: buildConfessionCard(confessions.first),
                            ),
                          )
                        : AnimatedSlide(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeInOut,
                            offset: singleCardOffset,
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeInOut,
                              turns: singleCardTurns,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.58,
                                child: buildConfessionCard(confessions.first),
                              ),
                            ),
                          ),
                  )
                : TinderSwapCard(
                    cardController: cardController,
                    animDuration: 220,
                    totalNum: confessions.length,
                    stackNum: confessions.length < 3 ? 2 : 3,
                    swipeEdge: 4,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    minWidth: MediaQuery.of(context).size.width * 0.82,
                    maxHeight: MediaQuery.of(context).size.height * 0.58,
                    minHeight: MediaQuery.of(context).size.height * 0.56,
                    swipeUp: false,
                    swipeDown: false,
                    swipeCompleteCallback: (
                      CardSwipeOrientation orientation,
                      int index,
                    ) {
                      handleSwipe(orientation, index);

                      if (index == confessions.length - 1) {
                        Future.delayed(
                          const Duration(milliseconds: 20),
                          () {
                            if (!mounted) return;

                            setState(() {
                              confessions = [];
                            });
                          },
                        );
                      }
                    },
                    cardBuilder: (context, index) {
                      return buildConfessionCard(confessions[index]);
                    },
                  ),
          ),
        ),
        const SizedBox(height: 24),
        buildActionButtons(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF080810),
        titleSpacing: 24,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Whisper',
              style: GoogleFonts.dmSerifDisplay(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            Text(
              'ANONYMOUS CONFESSIONS',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                letterSpacing: 4,
                color: Colors.white.withValues(alpha: 0.28),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: IconButton(
                onPressed: openProfile,
                tooltip: 'Your confessions',
                icon: Icon(
                  Icons.article_outlined,
                  color: Colors.white.withValues(alpha: 0.28),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: buildFeed(),
        ),
      ),
    );
  }
}
