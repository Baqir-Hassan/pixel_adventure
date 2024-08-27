import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/jump_button.dart';
// import 'package:flutter/painting.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/levels.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  PixelAdventure()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: 640,
            height: 360,
          ),
        );
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  // late CameraComponent cam;
  Player player = Player(character: "Pink Man");
  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = false;
  bool levelEnded = false;
  double soundVolume = 1.0;
  int currentLevelIndex = 0;
  List<String> levelNames = [
    'Level-01',
    'Level-02',
    'Level-03',
  ];
  @override
  FutureOr<void> onLoad() async {
    //Load all images into cache
    await images.loadAllImages();

    _loadLevel();
    if (showControls) {
      addJoyStick();
      camera.viewport.add(JumpButton());
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    super.update(dt);
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);
    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      currentLevelIndex = 0;
      _loadLevel();
      //no more levels
    }
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      world = Level(
        player: player,
        levelName: levelNames[currentLevelIndex],
      );

      camera.viewfinder.anchor = Anchor.topLeft;
    });
  }

  void addJoyStick() {
    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    // debugMode = true;
    camera.viewport.add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }
}
