import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum State { idle, run, hit }

class Chicken extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  late Checkpoint checkpoint;
  Chicken({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _hitAnimation;

  static const stepTime = 0.05;
  static const runSpeed = 80;
  final textureSize = Vector2(32, 34);

  Vector2 velocity = Vector2.zero();
  double rangeNeg = 0;
  double rangePos = 0;

  double moveDirection = 1;
  double targetDirection = -1;

  bool gotStomped = false;
  static const _bounceHeight = 260.0;
  late final Player player;
  static const tileSize = 16;
  @override
  FutureOr<void> onLoad() {
    player = game.player;
    add(RectangleHitbox(
      position: Vector2(4, 6),
      size: Vector2(24, 26),
    ));
    // debugMode = true;
    _loadAllAnimations();
    _calculateRange();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      _updateState();
      _movement(dt);
    }

    super.update(dt);
  }

  void _loadAllAnimations() {
    _idleAnimation = _spriteAnimation('Idle', 13);
    _runAnimation = _spriteAnimation('Run', 14);
    _hitAnimation = _spriteAnimation('Hit', 5)..loop = false;

    animations = {
      State.idle: _idleAnimation,
      State.run: _runAnimation,
      State.hit: _hitAnimation,
    };
    current = State.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Chicken/$state (32x34).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  void _movement(dt) {
    velocity.x = 0;
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double chickenOffset = (scale.x > 0) ? 0 : -width;

    if (playerInRange()) {
      targetDirection =
          (player.x + playerOffset < position.x + chickenOffset) ? -1 : 1;
      velocity.x = targetDirection * runSpeed;
    }

    moveDirection = lerpDouble(moveDirection, targetDirection, 1) ?? 1;
    position.x += velocity.x * dt;
  }

  bool playerInRange() {
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    return player.x + playerOffset >= rangeNeg &&
        player.x + playerOffset <= rangePos &&
        player.y + player.height > position.y &&
        player.y < position.y + height;
  }

  void _updateState() {
    current = (velocity.x != 0) ? State.run : State.idle;

    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      if (game.playSounds) {
        FlameAudio.play('bounce.wav', volume: game.soundVolume);
      }
      gotStomped = true;
      current = State.hit;
      player.velocity.y = -_bounceHeight;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedWithEnemy();
    }
  }
}
