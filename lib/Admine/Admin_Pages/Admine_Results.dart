import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../Services/topup_service.dart';
import '../../models/topup_request.dart';

class AdminTopupPage extends StatelessWidget {
  const AdminTopupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Top-Up Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Failed Points'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PendingRequestsTab(),
            FailedPointsTab(),
          ],
        ),
      ),
    );
  }
}

class PendingRequestsTab extends StatelessWidget {
  const PendingRequestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topupService = TopupService();

    return StreamBuilder<List<TopupRequest>>(
      stream: topupService.getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return RequestCard(
              request: requests[index],
              showRetry: false,
            );
          },
        );
      },
    );
  }
}

class FailedPointsTab extends StatelessWidget {
  const FailedPointsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topupService = TopupService();

    return StreamBuilder<List<TopupRequest>>(
      stream: topupService.getFailedPointsRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No failed requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return RequestCard(
              request: requests[index],
              showRetry: true,
            );
          },
        );
      },
    );
  }
}

class RequestCard extends StatefulWidget {
  final TopupRequest request;
  final bool showRetry;

  const RequestCard({
    Key? key,
    required this.request,
    required this.showRetry,
  }) : super(key: key);

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  final TopupService _topupService = TopupService();
  bool _isLoading = false;

  Future<void> _approveRequest() async {
    setState(() => _isLoading = true);
    try {
      await _topupService.approveRequest(
        widget.request.requestId,
        widget.request.userId,
        widget.request.amount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectRequest() async {
    setState(() => _isLoading = true);
    try {
      await _topupService.rejectRequest(widget.request.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _retryAddPoints() async {
    setState(() => _isLoading = true);
    try {
      await _topupService.retryAddPoints(
        widget.request.requestId,
        widget.request.userId,
        widget.request.amount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showScreenshot() {
    // Decode base64 to image
    Uint8List imageBytes = base64Decode(widget.request.screenshotBase64);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Screenshot'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.memory(imageBytes),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Decode base64 for thumbnail
    Uint8List imageBytes = base64Decode(widget.request.screenshotBase64);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rs. ${widget.request.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Method: ${widget.request.method}'),
                      Text('User ID: ${widget.request.userId}'),
                      Text(
                        'Date: ${widget.request.timestamp.toString().split('.')[0]}',
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showScreenshot,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (widget.showRetry)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _retryAddPoints,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Add Points'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approveRequest,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _rejectRequest,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}