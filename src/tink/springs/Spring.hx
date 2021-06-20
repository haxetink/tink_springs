package tink.springs;

import tink.state.internal.Invalidatable;
import tink.state.internal.*;
import tink.state.*;

using tink.CoreApi;

@:forward(set, startDrag, constrain, finished, velocity)
abstract Spring(SpringObject) to Observable<Float> {

  public var value(get, never):Float;
    @:to inline function get_value()
      return observable().value;

  public var config(get, never):Observable<SpringConfig>;
    @:to inline function get_config():Observable<SpringConfig>
      return @:privateAccess this.config;

  public function new(config, ?runner)
    this = new SpringObject(config, runner);

  public inline function observable():Observable<Float>
    return this;
}

class SpringObject implements Runner.Runnable extends Invalidator implements ObservableObject<Float> {

  @:unconfigurable public var velocity(default, null):Float = 0;
  @:unconfigurable public var finished(default, null) = false;

  var precision:Float = .005;
  final compare:Comparator<Float>;

  var position:Float = Math.NaN;
  var to:Float;

  var tension:Float = SpringConfig.DEFAULT_TENSION;
  var friction:Float = SpringConfig.DEFAULT_FRICTION;
  var mass:Float = 1;
  var stepSize:Float = 1;

  final config:State<SpringConfig>;

  public function isValid()
    return true;

  public function getComparator()
    return compare;

  public function getValue()
    return position;

  public final runner:Runner;

  public function new(config:SpringConfig, ?runner) {
    super();
    compare = (a, b) -> Math.abs(a - b) <= precision;

    this.min = Observable.auto(() -> getMin.value());
    this.max = Observable.auto(() -> getMax.value());

    var watchBounds = null;
    var onBoundsChange:Callback<Float> = _ -> {
      this.wakeup();
      if (this.drag == null) {
        position = constrain(position, (_, t) -> t);
      }
    }

    list.onfill = () -> watchBounds = min.bind(onBoundsChange, Scheduler.direct).join(max.bind(onBoundsChange, Scheduler.direct));
    list.ondrain = () -> watchBounds.cancel();

    this.position =
      switch config.from {
        case Math.isNaN(_) => true: config.to;
        case v: v;
      }

    this.velocity = config.velocity;
    this.config = new State(config);

    apply(config);

    this.runner = switch runner {
      case null: Runner.DEFAULT;
      case v: v;
    }

    this.runner.add(this);
  }

  function apply(config:SpringConfig) {
    config.applyTo(this);
  }

  function advance(dt:Float)
    return switch this.drag {
      case null:
        if (finished)
          return true;
        var isMoving = false;

        final restVelocity:Float = precision / 10;

        for (i in 0...Math.ceil(dt / stepSize)) {
          isMoving = Math.abs(velocity) > restVelocity;

          var delta = position - to;

          if (!isMoving) {
            finished = Math.abs(delta) <= precision;
            if (finished) {
              position = to;
              break;
            }
          }

          var springForce = if (Math.isNaN(delta)) .0 else -tension * 0.000001 * delta;
          var dampingForce = -friction * 0.001 * velocity;

          if (Math.isNaN(delta)) {
            dampingForce /= 2;
            this.to = switch constrain(position, (_, t) -> t) {
              case _ == position => true: Math.NaN;
              case v: v;
            }
          }

          var acceleration = (springForce + dampingForce) / mass;

          velocity += acceleration * stepSize;
          position += velocity * stepSize;
        }

        fire();

        return finished;
      case drag:
        if (position != drag.pos) {
          position = drag.pos;
          fire();
        }
        false;
    }

  @:unconfigurable var drag:Null<Drag>;

  public function startDrag(delta:Signal<Float>):CallbackLink {
    switch this.drag {
      case null:
      case v: v.stop();
    }

    var drag = new Drag(this.position, delta, (v) -> constrain(v, dragConstrain));
    this.drag = drag;

    wakeup();

    return () -> if (this.drag == drag) {
      this.velocity = drag.stop();
      this.position = drag.pos;
      this.to = Math.NaN;
      this.drag = null;
    }

  }

  public function set(config:SpringConfig) {

    apply(config);

    this.config.set(config);

    if (config.immediate && !Math.isNaN(config.to)) {
      position = constrain(config.to, (_, t) -> t);
      velocity = 0;
    }

    wakeup();
  }

  static function noMin()
    return Math.NEGATIVE_INFINITY;

  static function noMax()
    return Math.POSITIVE_INFINITY;

  final getMin = new State(noMin);
  final getMax = new State(noMax);
  final min:Observable<Float>;
  final max:Observable<Float>;

  static function rubber(desired:Float, constraint:Float) {
    var delta = Math.abs(desired - constraint),
        sign = if (desired > constraint) 1 else -1;

    var effective = sign * Math.pow(delta + 1, .85);//TODO: lot of magic numbers here ...

    return constraint + effective;
  }

  var dragConstrain:(desired:Float, constrained:Float)->Float = rubber;

  public function constrain(desired:Float, compute:(desired:Float, constraint:Float)->Float) {

    final min = min.value,
          max = max.value;

    return
      if (max < min)
        compute(desired, (min + max) / 2);
      else if (desired < min)
        compute(desired, min);
      else if (desired > max)
        compute(desired, max);
      else
        desired;
  }

  inline function wakeup()
    if (finished) {
      finished = false;
      runner.add(this);
    }
}

private class Drag {

  public var pos(default, null):Float;

  var speed:Float = 0;

  final link:CallbackLink;

  static inline function now()
    return Date.now().getTime();

  var lastTime:Float;

  public function new(pos:Float, delta:Signal<Float>, constrain) {
    this.pos = pos;

    lastTime = now();

    this.link = delta.handle(delta -> {

      pos += delta;

      updateSpeed(delta);

      this.pos = constrain(pos);

    });
  }

  function updateSpeed(delta:Float) {
    final now = now();
    final deltaT = now - lastTime;

    lastTime = now;

    speed = (delta + weight * speed) / (deltaT + weight);
  }

  static inline var weight = 50.0;

  public function stop():Float {
    link.cancel();
    updateSpeed(.0);
    return speed;
  }
}