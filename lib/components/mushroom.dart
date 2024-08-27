import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum MushroomState { hit, run }

class Mushroom extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  Mushroom({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _runAnimation;

  late final Player player;
  static const stepTime = 0.05;
  final textureSize = Vector2.all(32);

  double rangeNeg = 0;
  double rangePos = 0;
  double moveSpeed = 80;
  double moveDirection = -1;

  static const _bounceHeight = 260.0;

  bool gotStomped = false;

  static const tileSize = 16;

  @override
  FutureOr<void> onLoad() {
    player = game.player;

    add(
      RectangleHitbox(
        position: Vector2(4, 12),
        size: Vector2(24, 20),
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
    }
    super.update(dt);
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Mushroom/$state.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
  }

  void _loadAllAnimation() {
    _hitAnimation = _spriteAnimation('Hit', 5)..loop = false;
    _runAnimation = _spriteAnimation('Run (32x32)', 16);

    animations = {
      MushroomState.hit: _hitAnimation,
      MushroomState.run: _runAnimation,
    };
    current = MushroomState.run;
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

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      gotStomped = true;
      current = MushroomState.hit;
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
