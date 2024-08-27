import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum TurtleState { hit, idleSpikesIn, idleSpikesOut, spikesIn, spikesOut }

class Turtle extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  Turtle({
    super.position,
    super.size,
    this.offPos = 0,
    this.offNeg = 0,
  });

  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _idleSpikeInAnimation;
  late final SpriteAnimation _idleSpikeOutAnimation;
  late final SpriteAnimation _spikeOutAnimation;
  late final SpriteAnimation _spikeInAnimation;
  late final Player player;

  static const _bounceHeight = 260.0;
  static const stepTime = 0.05;
  static const tileSize = 16;

  final textureSize = Vector2(44, 26);

  double moveSpeed = 80;
  double moveDirection = -1;
  double rangeNeg = 0;
  double rangePos = 0;

  bool gotStomped = false;
  bool spikesIn = false;

  @override
  FutureOr<void> onLoad() {
    player = game.player;
    add(RectangleHitbox(
      position: Vector2(6, 6),
      size: Vector2(33, 19),
    ));

    // debugMode = true;
    add(TimerComponent(
      period: 4.0,
      repeat: true,
      onTick: swapState,
    ));
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
    _idleSpikeOutAnimation = _spriteAnimation('Idle 1', 14);
    _hitAnimation = _spriteAnimation('Hit', 5)..loop = false;
    _idleSpikeInAnimation = _spriteAnimation('Idle 2', 14);
    _spikeOutAnimation = _spriteAnimation('Spikes out', 8)..loop = false;
    _spikeInAnimation = _spriteAnimation('Spikes in', 8)..loop = false;

    animations = {
      TurtleState.idleSpikesIn: _idleSpikeInAnimation,
      TurtleState.idleSpikesOut: _idleSpikeOutAnimation,
      TurtleState.hit: _hitAnimation,
      TurtleState.spikesOut: _spikeOutAnimation,
      TurtleState.spikesIn: _spikeInAnimation,
    };
    current = TurtleState.idleSpikesOut;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Turtle/$state (44x26).png'),
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

  swapState() async {
    if (!spikesIn) {
      spikesIn = true;
      current = TurtleState.spikesIn;
      await animationTicker?.completed;
      animationTicker?.reset();
      current = TurtleState.idleSpikesIn;
    } else if (spikesIn) {
      current = TurtleState.spikesOut;
      await animationTicker?.completed;
      animationTicker?.reset();
      spikesIn = false;
      current = TurtleState.idleSpikesOut;
    }
  }

  void _updateState() {
    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
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

  void collidedWithPlayer() async {
    if (spikesIn) {
      if (player.velocity.y > 0 && player.y + player.height > position.y) {
        gotStomped = true;
        current = TurtleState.hit;
        player.velocity.y = -_bounceHeight;
        await animationTicker?.completed;
        removeFromParent();
      } else {
        player.collidedWithEnemy();
      }
    } else {
      player.collidedWithEnemy();
    }
  }
}
