import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:gtext/gtext.dart';
import 'Rewards.dart';

class SpinWheel_Widget extends StatefulWidget {
  final List<Reward> rewards;

  const SpinWheel_Widget({super.key, required this.rewards});

  @override
  _SpinWheel_WidgetState createState() => _SpinWheel_WidgetState();
}

class _SpinWheel_WidgetState extends State<SpinWheel_Widget>
    with SingleTickerProviderStateMixin {
  StreamController<int> controller = StreamController<int>.broadcast();
  int selectedReward = -1;
  late AnimationController _animationController;
  int? _latestRewardIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    controller.stream.listen((index) {
      setState(() {
        _latestRewardIndex = index;
      });
    });
  }

  @override
  void dispose() {
    controller.close();
    _animationController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    final rewardIndex = Fortune.randomInt(0, widget.rewards.length);
    controller.add(rewardIndex);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GText(
                  "You did so good! Spin the wheel to get a reward!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onPanEnd: (details) {
                    if (details.velocity.pixelsPerSecond.dx.abs() > 0 ||
                        details.velocity.pixelsPerSecond.dy.abs() > 0) {
                      _spinWheel();
                    }
                  },
                  child: SizedBox(
                    height: 600,
                    width: 600,
                    child: FortuneWheel(
                      animateFirst: false,
                      selected: controller.stream,
                      items: [
                        for (var reward in widget.rewards)
                          FortuneItem(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GText(
                                  reward.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Image.asset(reward.imagePath,
                                    height: 120, width: 120),
                              ],
                            ),
                            style: FortuneItemStyle(
                              color: Colors.primaries[
                                  widget.rewards.indexOf(reward) %
                                      Colors.primaries.length],
                              borderColor: Colors.white,
                              borderWidth: 2,
                            ),
                          ),
                      ],
                      onAnimationEnd: () {
                        if (_latestRewardIndex != null) {
                          setState(() {
                            selectedReward = _latestRewardIndex!;
                          });
                          _showRewardDialog();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _spinWheel,
                  child: GText('Spin the Wheel'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: GText('Exit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.2).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        GText(
                          widget.rewards[selectedReward].name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.asset(
                          widget.rewards[selectedReward].imagePath,
                          height: 300,
                          width: 300,
                        ),
                        const SizedBox(height: 15),
                        GText(
                          'Congratulations, you won ${widget.rewards[selectedReward].name}!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
