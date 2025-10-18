import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../api/leaderboard_api.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = LeaderboardApi.getLeaderboard();
  }

  Widget _getLeadingWidget(LeaderboardEntry entry, int position) {
    final rank = Text(
      '$position',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );

    Widget spriteWidget;
    if (entry.sprite == null) {
      // Give the icon a fixed size to match the image
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
          margin: EdgeInsets.symmetric(vertical: 5), 
          constraints: BoxConstraints(minWidth: 50), 
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Colors.black,
              )
            )
          ),     
          alignment: Alignment.centerLeft,
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
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No leaderboard data available.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final entry = snapshot.data![index];
                final position = index + 1;
                return Card(
                  color: _getCardColor(position),
                  child: ListTile(
                    leading: _getLeadingWidget(entry, position),
                    title: Text(
                      entry.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '${entry.score}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
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
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white;
    }
  }
}
