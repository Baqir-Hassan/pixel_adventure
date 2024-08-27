import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum Tramp { idle, jump }

class Trampoline extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  Trampoline({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  // late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _jumpAnimation;

  late final Player player;
  static const stepTime = 0.05;
  final textureSize = Vector2.all(28);

  Vector2 velocity = Vector2.zero();

  double rangeNeg = 0;
  double rangePos = 0;
  double moveSpeed = 80;
  double moveDirection = -1;

  static const _bounceHeight = 550.0;

  bool gotStomped = false;

  static const tileSize = 16;

  @override
  FutureOr<void> onLoad() {
    player = game.player;
    priority = -1;
    add(
      RectangleHitbox(
        position: Vector2(2, 17),
        size: Vector2(23, 14),
      ),
    );

    // debugMode = true;

    _loadAllAnimation();
    _calculateRange();
    return super.onLoad();
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Traps/Trampoline/$state.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
  }

  void _loadAllAnimation() {
    _idleAnimation = _spriteAnimation('Idle', 1);
    _jumpAnimation = _spriteAnimation('Jump (28x28)', 8)..loop = false;

    animations = {
      Tramp.idle: _idleAnimation,
      Tramp.jump: _jumpAnimation,
    };
    current = Tramp.idle;
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + width + offPos * tileSize;
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      gotStomped = true;
      current = Tramp.jump;
      player.velocity.y = -_bounceHeight;
      await animationTicker?.completed;
      current = Tramp.idle;
    }
  }
}
