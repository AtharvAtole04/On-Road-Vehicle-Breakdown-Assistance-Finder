// lib/views/feedback_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';

class FeedbackView extends StatefulWidget {
  final String orderId;
  final String
      recipientId; // the user who fulfilled the order (mechanic/helper)

  const FeedbackView(
      {Key? key, required this.orderId, required this.recipientId})
      : super(key: key);

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final _commentC = TextEditingController();
  int _rating = 5;
  bool _sending = false;
  bool _loadingExisting = true;
  bool _alreadySubmitted = false;
  Map<String, dynamic>? _existingFeedback;
  final AuthController _auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    // Check if current user already submitted feedback for this order
    try {
      final uid = _auth.appUser.value?.uid;
      if (uid == null) {
        setState(() {
          _loadingExisting = false;
          _alreadySubmitted = false;
        });
        return;
      }

      final q = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('orderId', isEqualTo: widget.orderId)
          .where('fromUserId', isEqualTo: uid)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        _existingFeedback = q.docs.first.data();
        setState(() {
          _alreadySubmitted = true;
          _loadingExisting = false;
          _rating = (_existingFeedback?['rating'] as int?) ?? 5;
          _commentC.text = _existingFeedback?['comment'] as String? ?? '';
        });
      } else {
        setState(() {
          _alreadySubmitted = false;
          _loadingExisting = false;
        });
      }
    } catch (e) {
      debugPrint('checkExisting feedback error: $e');
      setState(() {
        _loadingExisting = false;
        _alreadySubmitted = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_sending) return;
    // simple validation
    if (_rating < 1 || _rating > 5) {
      Get.snackbar('Invalid rating', 'Please provide a rating between 1 and 5');
      return;
    }
    setState(() => _sending = true);
    try {
      final fromUid = _auth.appUser.value?.uid ?? 'anonymous';
      final doc = {
        'orderId': widget.orderId,
        'recipientId': widget.recipientId,
        'fromUserId': fromUid,
        'rating': _rating,
        'comment': _commentC.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('feedbacks').add(doc);

      // Optional: mark order as feedbackGiven (if you want)
      // await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({'feedbackGiven': true});

      setState(() => _sending = false);
      Get.back(); // close view
      Get.snackbar('Thanks', 'Your feedback has been submitted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100);
    } catch (e) {
      debugPrint('feedback submit error: $e');
      setState(() => _sending = false);
      Get.snackbar('Error', 'Failed to send feedback',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    }
  }

  @override
  void dispose() {
    _commentC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_alreadySubmitted) ...[
                    Text('You already submitted feedback for this order',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildRatingRow(readOnly: true),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentC,
                      maxLines: 4,
                      readOnly: true,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Comment (already submitted)'),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ] else ...[
                    Text('Rate the helper', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildRatingRow(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentC,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          hintText: 'Write about the service...',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: Text(_sending ? 'Sending...' : 'Send Feedback'),
                        onPressed: _sending ? null : _submit,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRatingRow({bool readOnly = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final v = i + 1;
        return IconButton(
          onPressed: readOnly ? null : () => setState(() => _rating = v),
          icon: Icon(v <= _rating ? Icons.star : Icons.star_border,
              color: Colors.amber),
        );
      }),
    );
  }
}
