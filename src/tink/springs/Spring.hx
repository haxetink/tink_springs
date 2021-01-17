package tink.springs;

import tink.state.*;
import tink.state.internal.*;
import tink.state.internal.Invalidatable;

@:forward(set)
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
  
  @:unconfigurable var velocity:Float = 0;
  @:unconfigurable var finished = false;

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
    this.position = 
      switch config.from {
        case Math.isNaN(_) => true: config.to;
        case v: v;
      }

    this.velocity = config.velocity;
    this.config = new State(config);
    config.applyTo(this);
    
    this.runner = switch runner {
      case null: Runner.DEFAULT;
      case v: v;
    }

    this.runner.add(this);
  }

  function advance(dt:Float) {
    if (finished)
      return true;
    var isMoving = false;

    final restVelocity:Float = precision / 10;
    
    for (i in 0...Math.ceil(dt / stepSize)) {
      isMoving = Math.abs(velocity) > restVelocity;

      var delta = position - to;
      
      if (!isMoving) {
        finished = Math.abs(delta) <= precision;
        if (finished) 
          break;
      }

      var springForce = -tension * 0.000001 * delta;
      var dampingForce = -friction * 0.001 * velocity;
      var acceleration = (springForce + dampingForce) / mass;

      velocity += acceleration * stepSize;
      position += velocity * stepSize;
    }

    fire();

    return finished;
  }

  public function set(config:SpringConfig) {

    config.applyTo(this);
    this.config.set(config);

    if (config.immediate && !Math.isNaN(config.to)) {
      position = config.to;
      velocity = 0;
    }

    if (finished) {
      finished = false;
      runner.add(this);
    }
  }
}