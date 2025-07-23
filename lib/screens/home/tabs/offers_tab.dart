import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/item_service.dart';
import '../../../models/offer_model.dart';
import '../../../models/item_model.dart';

class OffersTab extends StatefulWidget {
  const OffersTab({super.key});

  @override
  State<OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends State<OffersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please sign in to view offers'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomingOffersTab(userId: userId),
          _OutgoingOffersTab(userId: userId),
        ],
      ),
    );
  }
}

class _IncomingOffersTab extends StatelessWidget {
  final String userId;

  const _IncomingOffersTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: ItemService().getOffersForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No incoming offers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone offers to swap with you, it will appear here',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _OfferCard(offer: offer, isIncoming: true);
          },
        );
      },
    );
  }
}

class _OutgoingOffersTab extends StatefulWidget {  // Changed to StatefulWidget
  final String userId;

  const _OutgoingOffersTab({required this.userId});

  @override
  State<_OutgoingOffersTab> createState() => _OutgoingOffersTabState();
}

class _OutgoingOffersTabState extends State<_OutgoingOffersTab> {
  late Stream<List<OfferModel>> _offersStream;
  final ItemService _itemService = ItemService();

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  void _loadOffers() {
    setState(() {
      _offersStream = _itemService.getOffersByUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: _offersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadOffers,  // Retry loading
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No outgoing offers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'When you make offers, they will appear here',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _OfferCard(offer: offer, isIncoming: false);
          },
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool isIncoming;

  const _OfferCard({
    required this.offer,
    required this.isIncoming,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(offer.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(offer.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Offer Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You\'re offering:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<ItemModel?>(
                        future: ItemService().getItemById(offer.offeredItemId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 16,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          } else if (snapshot.hasData && snapshot.data != null) {
                            final item = snapshot.data!;
                            return Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            );
                          } else {
                            return const Text(
                              'Item not found',
                              style: TextStyle(color: Colors.redAccent),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.swap_horiz),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'For:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<ItemModel?>(
                        future: ItemService().getItemById(offer.targetItemId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 16,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          } else if (snapshot.hasData && snapshot.data != null) {
                            final item = snapshot.data!;
                            return Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            );
                          } else {
                            return const Text(
                              'Item not found',
                              style: TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.end,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],

            if (isIncoming && offer.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToOffer(context, offer, false),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToOffer(context, offer, true),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return Colors.orange;
      case OfferStatus.accepted:
        return Colors.green;
      case OfferStatus.rejected:
        return Colors.red;
      case OfferStatus.cancelled:
        return Colors.grey;
      case OfferStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _respondToOffer(BuildContext context, OfferModel offer, bool accept) {
    final status = accept ? OfferStatus.accepted : OfferStatus.rejected;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Accept Offer' : 'Decline Offer'),
        content: Text(
          accept
              ? 'Are you sure you want to accept this offer? This will create a chat for coordination.'
              : 'Are you sure you want to decline this offer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ItemService().respondToOffer(offer.id, status);
                if (accept && context.mounted) {
                  Navigator.of(context).pushNamed('/chat', arguments: offer.id);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text(accept ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );
  }
}