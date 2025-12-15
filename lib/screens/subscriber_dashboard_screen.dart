import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rattil/providers/iap_provider.dart';
import 'package:rattil/models/package.dart';
import 'package:rattil/widgets/package_card.dart';
import 'package:rattil/widgets/app_bar_widget.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:collection/collection.dart';

class SubscriberDashboardScreen extends StatelessWidget {
  const SubscriberDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        notificationCount: 0,
        onMenuTap: () => Scaffold.of(context).openDrawer(),
        onNotificationTap: () {},
      ),
      body: Consumer<IAPProvider>(
        builder: (context, iapProvider, child) {
          // Find the purchased package (assuming only one active at a time)
          final purchased = iapProvider.purchases.firstWhereOrNull(
            (purchase) => purchase.status == PurchaseStatus.purchased,
          );
          if (purchased == null) {
            return Center(
              child: Text(
                'No active subscription. Please purchase a package to unlock content.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Map purchase to package (assuming productId matches package id)
          final package = packages.firstWhere(
            (pkg) => pkg.id.toString().padLeft(2, '0') == purchased.productID,
            orElse: () => packages.first,
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscriber Dashboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                PackageCard(
                  package: package,
                  delay: 0,
                  isLoading: false,
                ),
                const SizedBox(height: 24),
                Text(
                  'Downloadable Material:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('View PDF Material'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PDFViewerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Material'),
      ),
      body: SfPdfViewer.asset('assets/pdf/rattil_app_testing.pdf'),
    );
  }
}
