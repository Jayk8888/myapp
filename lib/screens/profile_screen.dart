import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/confession.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Confession> _confessions = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfessions();
  }

  Future<void> _loadConfessions({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _refreshing = true);
    } else {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final confessions = await _fetchMyConfessions();
      if (!mounted) return;

      setState(() {
        _confessions = confessions;
        _loading = false;
        _refreshing = false;
        _errorMessage = null;
      });
    } catch (error) {
      debugPrint('Profile confessions error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
        _errorMessage = _loadErrorMessage(error);
      });
    }
  }

  Future<List<Confession>> _fetchMyConfessions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('confessions')
        .where('authorId', isEqualTo: uid)
        .get();

    final confessions = snap.docs.map(Confession.fromFirestore).toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return confessions;
  }

  String _loadErrorMessage(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Firestore denied access.\nCheck your security rules.';
    }

    return 'Could not load your confessions.';
  }

  Future<void> _editConfession(Confession confession) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditConfessionDialog(initialText: confession.text),
    );

    if (!mounted || updated == null || updated.isEmpty) return;
    if (updated == confession.text) return;

    final previous = _confessions;
    setState(() {
      _confessions = _confessions
          .map((c) => c.id == confession.id ? c.copyWith(text: updated) : c)
          .toList();
    });

    try {
      await FirebaseFirestore.instance
          .collection('confessions')
          .doc(confession.id)
          .update({'text': updated});
    } catch (error) {
      if (!mounted) return;

      setState(() => _confessions = previous);
      _showSnackBar('Could not update confession.');
    }
  }

  Future<void> _deleteConfession(Confession confession) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    final previous = _confessions;
    setState(() {
      _confessions =
          _confessions.where((c) => c.id != confession.id).toList();
    });

    try {
      await FirebaseFirestore.instance
          .collection('confessions')
          .doc(confession.id)
          .delete();
    } catch (error) {
      if (!mounted) return;

      setState(() => _confessions = previous);
      _showSnackBar('Could not delete confession.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          message,
          style: GoogleFonts.spaceMono(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildConfessionsBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white24,
          strokeWidth: 1.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _loadConfessions(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderStrong),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: Text(
                  'retry',
                  style: GoogleFonts.spaceMono(fontSize: 11, letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_confessions.isEmpty) {
      return Center(
        child: Text(
          "you haven't whispered yet",
          style: GoogleFonts.dmSerifDisplay(
            color: AppColors.textMuted,
            fontSize: 18,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.textMuted,
      backgroundColor: AppColors.surface,
      onRefresh: () => _loadConfessions(isRefresh: true),
      child: Stack(
        children: [
          ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _confessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ConfessionTile(
              confession: _confessions[i],
              onEdit: () => _editConfession(_confessions[i]),
              onDelete: () => _deleteConfession(_confessions[i]),
            ),
          ),
          if (_refreshing)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.textMuted,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    // Pop profile (and any other routes) so the auth-driven home shows login.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnon = user?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080810),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'my confessions',
          style: GoogleFonts.dmSerifDisplay(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isAnon)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101018),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add,
                          color: Colors.white38, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'posting as ghost — confessions disappear on sign out',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: _buildConfessionsBody()),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 68,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentDislike,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'sign out',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfessionTile extends StatelessWidget {
  const _ConfessionTile({
    required this.confession,
    required this.onEdit,
    required this.onDelete,
  });

  final Confession confession;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: confession.color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  confession.text,
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Stat(
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFF7B61FF),
                      value: confession.likes,
                    ),
                    const SizedBox(width: 16),
                    _Stat(
                      icon: Icons.close_rounded,
                      color: const Color(0xFFFF6B6B),
                      value: confession.dislikes,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white54,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditConfessionDialog extends StatefulWidget {
  const _EditConfessionDialog({required this.initialText});

  final String initialText;

  @override
  State<_EditConfessionDialog> createState() => _EditConfessionDialogState();
}

class _EditConfessionDialogState extends State<_EditConfessionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'edit confession',
                style: GoogleFonts.dmSerifDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 2,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.dmSerifDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'your confession',
                    hintStyle: GoogleFonts.dmSerifDisplay(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => canSave ? _save() : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderStrong),
                          foregroundColor: AppColors.textSecondary,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'cancel',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: canSave ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.background,
                          disabledBackgroundColor:
                              AppColors.textPrimary.withValues(alpha: 0.2),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'save',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'delete confession?',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'this cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderStrong),
                          foregroundColor: AppColors.textSecondary,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'cancel',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                AppColors.accentDislike.withValues(alpha: 0.5),
                          ),
                          foregroundColor: AppColors.accentDislike,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'delete',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 15,
                            color: AppColors.accentDislike,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value});
  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: GoogleFonts.spaceMono(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
