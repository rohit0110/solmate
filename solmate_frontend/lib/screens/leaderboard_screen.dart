import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/leaderboard_api.dart';
import '../models/leaderboard_data.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  final String pubkey;

  const LeaderboardScreen({super.key, required this.pubkey});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<LeaderboardData> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = LeaderboardApi.getLeaderboard(widget.pubkey);
  }

  Widget _getLeadingWidget(LeaderboardEntry entry) {
    final rank = Text(
      '${entry.rank}',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );

    Widget spriteWidget;
    if (entry.sprite == null) {
      spriteWidget = const SizedBox(width: 40, height: 40, child: Icon(Icons.person));
    } else {
      final imageBytes = base64Decode(entry.sprite!);
      spriteWidget = Image.memory(
        imageBytes,
        width: 40,
        height: 40,
        filterQuality: FilterQuality.none,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          alignment: Alignment.centerRight,
          child: rank,
        ),
        const SizedBox(width: 10),
        spriteWidget,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: FutureBuilder<LeaderboardData>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading leaderboard.'));
          } else if (!snapshot.hasData || snapshot.data!.leaderboard.isEmpty) {
            return const Center(child: Text('No leaderboard data available.'));
          } else {
            final data = snapshot.data!;
            final leaderboard = data.leaderboard;
            final userEntry = data.user;

            int itemCount = leaderboard.length;
            if (userEntry != null) {
              itemCount += 2; // For separator and user card
            }

            return ListView.builder(
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // Top 20 list
                if (index < leaderboard.length) {
                  final entry = leaderboard[index];
                  final isUser = entry.pubkey == widget.pubkey;
                  return Card(
                    color: isUser ? Colors.teal.shade100 : _getCardColor(entry.rank),
                    child: ListTile(
                      leading: _getLeadingWidget(entry),
                      title: Text(
                        entry.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${entry.score}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  );
                }

                // Separator
                if (userEntry != null && index == leaderboard.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.more_horiz),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  );
                }

                // User's rank card
                if (userEntry != null && index > leaderboard.length) {
                  return Card(
                    color: Colors.teal.shade100, // Highlight color
                    child: ListTile(
                      leading: _getLeadingWidget(userEntry),
                      title: Text(
                        userEntry.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${userEntry.score}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  );
                }

                return null; // Should not happen
              },
            );
          }
        },
      ),
    );
  }

  Color _getCardColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade300;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white;
    }
  }
}
