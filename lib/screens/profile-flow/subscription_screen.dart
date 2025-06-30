import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentPlan = 'free';
  bool _yearlyBilling = true;

  final Uri _hostedPaymentUrl = Uri.parse(dotenv.env['HOSTED_PAYMENT_URL']!);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = Theme.of(context).colorScheme.primary;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[800];

    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Plan'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              fontWeight:
                                  !_yearlyBilling
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                        Switch(
                          value: _yearlyBilling,
                          activeColor: highlightColor,
                          onChanged: (value) {
                            setState(() {
                              _yearlyBilling = value;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Yearly',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight:
                                  _yearlyBilling
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              title: 'Free Plan',
              price: 'Free',
              features: const [
                'Basic features',
                'Unlimited Scrolling',
                'All AP Classes',
              ],
              missingFeatures: const ['Custom Study Sets'],
              isActive: _currentPlan == 'free',
              cardColor: cardColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              highlightColor: highlightColor,
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              title: 'Plus Plan',
              price: _yearlyBilling ? '\$10/year' : '\$1/month',
              features: const [
                'All features from Free Plan',
                'Custom Study Sets',
                'Priority Support',
                'New Features',
              ],
              isActive: _currentPlan == 'plus',
              isPlus: true,
              savings: _yearlyBilling ? 'Save \$2/year' : null,
              cardColor: cardColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              highlightColor: highlightColor,
            ),
            if (_currentPlan != 'plus')
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ElevatedButton(
                  onPressed: launchHostedCheckout,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    backgroundColor: highlightColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Subscribe to Plus Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    List<String> missingFeatures = const [],
    required bool isActive,
    bool isPlus = false,
    String? savings,
    required Color? cardColor,
    required Color textColor,
    required Color? secondaryTextColor,
    required Color highlightColor,
  }) {
    return Card(
      elevation: 6,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? highlightColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPlus ? highlightColor : textColor,
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: highlightColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current Plan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: highlightColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (savings != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  savings,
                  style: TextStyle(
                    color: Colors.green[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Divider(height: 30, color: secondaryTextColor),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 18, color: highlightColor),
                    const SizedBox(width: 8),
                    Text(feature, style: TextStyle(color: textColor)),
                  ],
                ),
              ),
            ),
            ...missingFeatures.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.close, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> launchHostedCheckout() async {
    if (!await launchUrl(_hostedPaymentUrl)) {
      throw Exception('Could not launch $_hostedPaymentUrl');
    }
  }
}
