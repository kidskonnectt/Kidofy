import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/services/connectivity_service.dart';
import 'package:kidsapp/services/supabase_service.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.orange[900],
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'OFFLINE MODE - Using downloaded videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Retrying connection...')),
                  );
                  await SupabaseService.initializeData();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: "Reload Data",
              ),
            ],
          ),
        );
      },
    );
  }
}
