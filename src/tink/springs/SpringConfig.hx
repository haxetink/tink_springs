package tink.springs;

import tink.springs.Spring.SpringObject;

@:forward
abstract SpringConfig(SpringConfigData) from SpringConfigData {
  @:from static inline function ofFloat(f:Float):SpringConfig
    return { to: f };

  // static public final DEFAULT:SpringConfig = { tension: DEFAULT_TENSION, friction: DEFAULT_FRICTION };
  // static public final GENTLE:SpringConfig = { tension: 120, friction: 14 };
  // static public final WOBBLY:SpringConfig = { tension: 180, friction: 12 };
  // static public final STIFF:SpringConfig = { tension: 210, friction: 20 };
  // static public final SLOW:SpringConfig = { tension: 280, friction: 60 };
  // static public final MOLASSES:SpringConfig = { tension: 280, friction: 120 };

  @:noCompletion static public inline var DEFAULT_TENSION = 170;
  @:noCompletion static public inline var DEFAULT_FRICTION = 26;

}

@:build(tink.springs.SpringConfig.build())
@:structInit
@:access(tink.springs)
class SpringConfigData {
  public final from:Float = Math.NaN;
  public final velocity:Float = 0;
  public final immediate:Bool = false;
  public var getMin:()->Float = null;
  public var getMax:()->Float = null;

  @:allow(tink.springs)
  function applyTo(s:SpringObject) {
    switch getMin {
      case null:
      case v: s.getMin.set(v);
    }

    switch getMax {
      case null:
      case v: s.getMax.set(v);
    }

    setNumbers(s);
  }
}