import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
// import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum RockState { idle, hit, run }

class Rocks extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  Rocks({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _runAnimation;
  late final Player player;

  static const stepTime = 0.05;
  static const _bounceHeight = 200.0;
  static const tileSize = 16;

  double rangeNeg = 0;
  double rangePos = 0;
  double moveSpeed = 80;
  double moveDirection = -1;

  bool gotStomped = false;

  final textureSize = Vector2(38, 34);

  @override
  FutureOr<void> onLoad() {
    player = game.player;

    add(
      RectangleHitbox(
        position: Vector2(1, 3),
        size: Vector2(36, 31),
      ),
    );

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

  _loadAllAnimations() {
    _idleAnimation = _spriteAnimation('Rock1_Idle', 14);
    _hitAnimation = _spriteAnimation('Rock1_Hit', 1)..loop = false;
    _runAnimation = _spriteAnimation('Rock1_Run', 14);

    animations = {
      RockState.idle: _idleAnimation,
      RockState.hit: _hitAnimation,
      RockState.run: _runAnimation,
    };
    current = RockState.run;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Rocks/$state (38x34).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + width + offPos * tileSize;
  }

  void _updateState() {
    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void _movement(double dt) {
    if (position.x < rangeNeg) {
      moveDirection = 1;
    } else if (position.x > rangePos) {
      moveDirection = -1;
    }
    position.x += moveSpeed * moveDirection * dt;
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      gotStomped = true;
      current = RockState.hit;
      player.velocity.y = -_bounceHeight;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedWithEnemy();
    }
  }
}
