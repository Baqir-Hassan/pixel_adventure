import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum AngryPigState { walk, hit, run }

class AngryPig extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  AngryPig({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  late final SpriteAnimation _walkAnimation;
  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _runAnimation;

  late final Player player;
  static const stepTime = 0.05;
  final textureSize = Vector2(36, 32);

  Vector2 velocity = Vector2.zero();

  double rangeNeg = 0;
  double rangePos = 0;
  double moveSpeed = 80;
  double runSpeed = 100;
  double moveDirection = -1;
  double targetDirection = 1;

  static const _bounceHeight = 260.0;

  bool gotStomped = false;

  // static const _bounceHeight = 260;
  static const tileSize = 16;

  @override
  FutureOr<void> onLoad() {
    player = game.player;

    add(
      RectangleHitbox(
        position: Vector2(2, 2),
        size: Vector2(30, 30),
      ),
    );

    // debugMode = true;

    _loadAllAnimation();
    _calculateRange();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      _updateState();
      _movement(dt);
      if (playerInRange()) {
        _chase(dt);
      } else {
        current = AngryPigState.walk;
      }
    }
    super.update(dt);
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/AngryPig/$state (36x30).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
  }

  void _loadAllAnimation() {
    _walkAnimation = _spriteAnimation('Walk', 16);
    _hitAnimation = _spriteAnimation('Hit 1', 5)..loop = false;
    _runAnimation = _spriteAnimation('Run', 12);

    animations = {
      AngryPigState.hit: _hitAnimation,
      AngryPigState.walk: _walkAnimation,
      AngryPigState.run: _runAnimation,
    };
    current = AngryPigState.walk;
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + width + offPos * tileSize;
  }

  void _updateState() {
    // current = (velocity.x != 0) ? AngryPigState.run : AngryPigState.idle;

    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      gotStomped = true;
      current = AngryPigState.hit;
      player.velocity.y = -_bounceHeight;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedWithEnemy();
    }
  }

  void _movement(double dt) {
    velocity.x = 0;
    // double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    // double chickenOffset = (scale.x > 0) ? 0 : -width;

    if (position.x >= rangePos) {
      moveDirection = -1;
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
    }
    position.x += moveSpeed * moveDirection * dt;
  }

  bool playerInRange() {
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    return player.x + playerOffset >= rangeNeg &&
        player.x + playerOffset <= rangePos &&
        player.y + player.height > position.y &&
        player.y < position.y + height;
  }

  void _chase(dt) {
    velocity.x = 0;
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double chickenOffset = (scale.x > 0) ? 0 : -width;

    if (playerInRange()) {
      current = AngryPigState.run;
      targetDirection =
          (player.x + playerOffset < position.x + chickenOffset) ? -1 : 1;
      velocity.x = targetDirection * runSpeed;
    }

    moveDirection = lerpDouble(moveDirection, targetDirection, 1) ?? 1;
    position.x += velocity.x * dt;
  }
}
