import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class DrawingPoint {
  final Offset point;
  final Paint paint;

  DrawingPoint(this.point, this.paint);
}

class DrawingSegment {
  final List<DrawingPoint> points;
  final bool isEraser;

  DrawingSegment({required this.points, this.isEraser = false});
}

class DrawingPage extends StatefulWidget {
  final String roomId;
  final String userName;
  final bool isHost;

  const DrawingPage({
    super.key,
    required this.roomId,
    required this.userName,
    required this.isHost,
  });

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late WebSocketChannel channel;
  Color selectedColor = Colors.black;
  bool isEraser = false;
  List<DrawingSegment> segments = [];
  List<DrawingPoint> currentSegment = [];
  double strokeWidth = 3.0;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://drawingchatserver-2.onrender.com/ws'),
      );

      // Send initial room join message
      channel.sink.add(jsonEncode({
        'room_id': widget.roomId,
        'type': 'join',
        'user_name': widget.userName
      }));

      // Listen for incoming drawing data
      channel.stream.listen(
            (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'draw') {
            setState(() {
              segments.add(DrawingSegment(
                points: [
                  DrawingPoint(
                    Offset(data['start_x'], data['start_y']),
                    Paint()
                      ..color = Color(data['color'])
                      ..isAntiAlias = true
                      ..strokeWidth = data['is_eraser'] ? 20.0 : data['stroke_width']
                      ..strokeCap = StrokeCap.round,
                  ),
                  DrawingPoint(
                    Offset(data['end_x'], data['end_y']),
                    Paint()
                      ..color = Color(data['color'])
                      ..isAntiAlias = true
                      ..strokeWidth = data['is_eraser'] ? 20.0 : data['stroke_width']
                      ..strokeCap = StrokeCap.round,
                  ),
                ],
                isEraser: data['is_eraser'],
              ));
            });
          } else if (data['type'] == 'clear') {
            setState(() {
              segments.clear();
              currentSegment.clear();
            });
          }
        },
        onDone: () {
          setState(() {
            isConnected = false;
          });
        },
        onError: (error) {
          setState(() {
            isConnected = false;
          });
        },
      );

      setState(() {
        isConnected = true;
      });
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  void broadcastDrawing(Offset start, Offset end) {
    if (!isConnected) return;

    channel.sink.add(jsonEncode({
      'type': 'draw',
      'room_id': widget.roomId,
      'user_name': widget.userName,
      'start_x': start.dx,
      'start_y': start.dy,
      'end_x': end.dx,
      'end_y': end.dy,
      'color': selectedColor.value,
      'is_eraser': isEraser,
      'stroke_width': strokeWidth,
    }));
  }

  void broadcastClear() {
    if (!isConnected) return;

    channel.sink.add(jsonEncode({
      'type': 'clear',
      'room_id': widget.roomId,
      'user_name': widget.userName,
    }));
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId}'),
        actions: [
          if (!isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: connectToServer,
              tooltip: 'Reconnect',
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${widget.userName} (${widget.isHost ? 'Host' : 'Guest'})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
          ),
          GestureDetector(
            onPanStart: (details) {
              currentSegment = [];
              currentSegment.add(
                DrawingPoint(
                  details.localPosition,
                  Paint()
                    ..color = isEraser ? Colors.white : selectedColor
                    ..isAntiAlias = true
                    ..strokeWidth = isEraser ? 20.0 : strokeWidth
                    ..strokeCap = StrokeCap.round,
                ),
              );
              setState(() {});
            },
            onPanUpdate: (details) {
              final newPoint = DrawingPoint(
                details.localPosition,
                Paint()
                  ..color = isEraser ? Colors.white : selectedColor
                  ..isAntiAlias = true
                  ..strokeWidth = isEraser ? 20.0 : strokeWidth
                  ..strokeCap = StrokeCap.round,
              );

              currentSegment.add(newPoint);

              if (currentSegment.length > 1) {
                broadcastDrawing(
                  currentSegment[currentSegment.length - 2].point,
                  currentSegment[currentSegment.length - 1].point,
                );
              }

              setState(() {});
            },
            onPanEnd: (details) {
              if (currentSegment.isNotEmpty) {
                segments.add(DrawingSegment(
                  points: List.from(currentSegment),
                  isEraser: isEraser,
                ));
              }
              currentSegment = [];
              setState(() {});
            },
            child: CustomPaint(
              painter: DrawingPainter(
                segments: segments,
                currentSegment: currentSegment,
              ),
              size: Size.infinite,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorButton(Colors.black),
                      _buildColorButton(Colors.red),
                      _buildColorButton(Colors.blue),
                      _buildColorButton(Colors.green),
                      _buildColorButton(Colors.yellow),
                      _buildEraserButton(),
                      _buildClearButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Stroke Width: '),
                      Expanded(
                        child: Slider(
                          value: strokeWidth,
                          min: 1,
                          max: 10,
                          onChanged: (value) {
                            setState(() {
                              strokeWidth = value;
                              isEraser = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
          isEraser = false;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color && !isEraser ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildEraserButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isEraser = !isEraser;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEraser ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.auto_fix_high,
          size: 20,
          color: isEraser ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        setState(() {
          segments.clear();
          currentSegment.clear();
          broadcastClear();
        });
      },
      tooltip: 'Clear Canvas',
    );
  }
}
class DrawingPainter extends CustomPainter {
  final List<DrawingSegment> segments;
  final List<DrawingPoint> currentSegment;

  DrawingPainter({
    required this.segments,
    required this.currentSegment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed segments
    for (var segment in segments) {
      for (int i = 0; i < segment.points.length - 1; i++) {
        if (segment.points[i].point != Offset.zero &&
            segment.points[i + 1].point != Offset.zero) {
          canvas.drawLine(
            segment.points[i].point,
            segment.points[i + 1].point,
            segment.points[i].paint,
          );
        }
      }
    }

    // Draw current segment (the one being drawn)
    for (int i = 0; i < currentSegment.length - 1; i++) {
      if (currentSegment[i].point != Offset.zero &&
          currentSegment[i + 1].point != Offset.zero) {
        canvas.drawLine(
          currentSegment[i].point,
          currentSegment[i + 1].point,
          currentSegment[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}