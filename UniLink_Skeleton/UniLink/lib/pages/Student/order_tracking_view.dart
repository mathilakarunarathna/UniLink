import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/util/date_util.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_card.dart';

class OrderTrackingView extends StatelessWidget {
  final String orderId;

  const OrderTrackingView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data()!;
        final status = data['status'] ?? 'Pending';
        final shopName = data['shopName'] ?? 'Campus Kitchen';
        final estimatedReadyAt = DateUtil.parseNullable(data['estimatedReadyAt']);
        final items = (data['items'] as List?) ?? [];
        final totalAmount = data['totalAmount'] ?? 0.0;
        final currency = data['currency'] ?? 'LKR';

        // Calculate time remaining
        int minutesLeft = 0;
        if (estimatedReadyAt != null) {
          final diff = estimatedReadyAt.difference(DateTime.now());
          minutesLeft = diff.inMinutes;
          if (minutesLeft < 0) minutesLeft = 0;
        }

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: colors.foreground),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Order Tracking',
              style: TextStyle(color: colors.foreground, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(status, minutesLeft, colors),
                const SizedBox(height: 24),
                _buildOrderDetails(shopName, data['orderNumber'] ?? '---', items, totalAmount, currency, colors),
                const SizedBox(height: 32),
                _buildTrackingSteps(status, colors),
                const SizedBox(height: 40),
                if (status == 'Ready')
                  _buildPickupInstructions(colors)
                else
                  _buildPreparationNotes(colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(String status, int minutesLeft, AppCustomColors colors) {
    Color bannerColor = colors.primary;
    IconData icon = LucideIcons.clock;
    String title = "Order Received";
    String subtitle = "Waiting for kitchen to confirm...";

    if (status == 'Preparing') {
      bannerColor = colors.campusAmber;
      icon = LucideIcons.utensils;
      title = "Preparing Your Meal";
      subtitle = minutesLeft > 0 
          ? "Ready in approximately $minutesLeft minutes"
          : "Almost ready!";
    } else if (status == 'Ready') {
      bannerColor = colors.campusEmerald;
      icon = LucideIcons.checkCircle;
      title = "Ready for Pickup!";
      subtitle = "Head to the counter to collect your order";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bannerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bannerColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: bannerColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(String shop, String orderNum, List items, dynamic total, String currency, AppCustomColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ORDER SUMMARY",
          style: TextStyle(
            color: colors.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(shop, style: TextStyle(fontWeight: FontWeight.bold, color: colors.foreground)),
                  Text(orderNum, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800)),
                ],
              ),
              const Divider(height: 24),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item['quantity']}x ${item['itemName']}", style: TextStyle(color: colors.foreground)),
                    Text("$currency ${item['lineTotal']}", style: TextStyle(color: colors.mutedForeground, fontSize: 13)),
                  ],
                ),
              )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Paid", style: TextStyle(fontWeight: FontWeight.bold, color: colors.foreground)),
                  Text("$currency ${total.toStringAsFixed(2)}", 
                    style: TextStyle(fontWeight: FontWeight.w900, color: colors.foreground, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingSteps(String currentStatus, AppCustomColors colors) {
    final steps = ["Pending", "Preparing", "Ready", "Completed"];
    final currentIndex = steps.indexOf(currentStatus);

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentIndex;
        final isActive = index == currentIndex;
        final color = isCompleted || isActive ? colors.primary : colors.muted;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? colors.primary : (isCompleted ? colors.primary.withValues(alpha: 0.2) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isCompleted 
                    ? Icon(LucideIcons.check, size: 14, color: colors.primary)
                    : (isActive ? Container(margin: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)) : null),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted ? colors.primary : colors.muted,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index],
                    style: TextStyle(
                      color: color,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPickupInstructions(AppCustomColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.campusEmerald.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.campusEmerald.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: colors.campusEmerald),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Show your digital receipt or order number at the counter to pickup your food.",
              style: TextStyle(color: colors.campusEmerald, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationNotes(AppCustomColors colors) {
    return Center(
      child: Text(
        "We'll notify you when your order is ready.",
        style: TextStyle(color: colors.mutedForeground, fontSize: 12, fontStyle: FontStyle.italic),
      ),
    );
  }
}
