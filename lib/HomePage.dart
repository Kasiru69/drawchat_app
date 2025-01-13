import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'DrawingPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Rooms'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String userName = '';
                    return AlertDialog(
                      title: const Text('Create Room'),
                      content: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Enter your name',
                          hintText: 'Name',
                        ),
                        onChanged: (value) {
                          userName = value;
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (userName.isNotEmpty) {
                              String roomId = generateRoomId();
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DrawingPage(
                                    roomId: roomId,
                                    userName: userName,
                                    isHost: true,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Create'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Create Room'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String userName = '';
                    String roomId = '';
                    return AlertDialog(
                      title: const Text('Join Room'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Enter room ID',
                              hintText: 'Room ID',
                            ),
                            onChanged: (value) {
                              roomId = value;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Enter your name',
                              hintText: 'Name',
                            ),
                            onChanged: (value) {
                              userName = value;
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (userName.isNotEmpty && roomId.isNotEmpty) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DrawingPage(
                                    roomId: roomId,
                                    userName: userName,
                                    isHost: false,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Join'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}

String generateRoomId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(Iterable.generate(
    6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
  ));
}
