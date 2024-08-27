import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum BirdState { flying, hit }

class BlueBird extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  BlueBird({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  late final SpriteAnimation _flyingAnimation;
  late final SpriteAnimation _hitAnimation;

  late final Player player;

  static const stepTime = 0.05;
  final textureSize = Vector2.all(32);

  Vector2 velocity = Vector2.zero();
  double rangeNeg = 0;
  double rangePos = 0;
  double moveSpeed = 90;
  double moveDirection = -1;

  static const _bounceHeight = 270.0;
  static const tileSize = 16;

  bool gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    player = game.player;

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
    add(RectangleHitbox(
      position: Vector2(3, 4),
      size: Vector2(27, 26),
    ));

    // debugMode = true;

    _flyingAnimation = _spriteAnimation('Flying', 9);
    _hitAnimation = _spriteAnimation('Hit', 5)..loop = false;

    animations = {
      BirdState.hit: _hitAnimation,
      BirdState.flying: _flyingAnimation,
    };
    current = BirdState.flying;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/BlueBird/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + (width) + offPos * tileSize;
  }

  void _updateState() {
    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      gotStomped = true;
      current = BirdState.hit;
      player.velocity.y = -_bounceHeight;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedWithEnemy();
    }
  }

  void _movement(double dt) {
    if (position.x >= rangePos) {
      moveDirection = -1;
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
    }

    position.x += moveSpeed * moveDirection * dt;
  }
}
