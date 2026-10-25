import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/restaurant_detail_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/app_strings.dart';

class ReviewForm extends StatefulWidget {
  final String restaurantId;
  const ReviewForm({super.key, required this.restaurantId});

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _commentCtrl = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<RestaurantDetailProvider>();
    final lang = context.read<LocaleProvider>().languageCode;
    final success = await provider.submitReview(
      widget.restaurantId,
      _rating,
      _commentCtrl.text.trim(),
    );
    if (success && mounted) {
      _commentCtrl.clear();
      setState(() => _rating = 5);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('review_published', lang))),
      );
    }
    // Si échec (ex: 409 ALREADY_REVIEWED), le message est déjà dans
    // provider.reviewError et affiché ci-dessous — pas de crash.
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantDetailProvider>();
    final lang = context.watch<LocaleProvider>().languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t('leave_review', lang)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _rating = starIndex),
                  );
                }),
              ),
              TextField(
                controller: _commentCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: AppStrings.t('your_comment', lang),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (provider.reviewError != null) ...[
                const SizedBox(height: 8),
                Text(
                  provider.reviewError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: provider.isSubmittingReview
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        child: Text(AppStrings.t('publish', lang)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
