package tink.springs;

class Runner {
  final runnables:Array<Runnable> = [];
  final running = [];
  final schedule:(()->Void)->(()->Void);

  public function new(schedule) {
    this.schedule = schedule;
  }

  var last:Float = .0;

  function advance() {
    var now = haxe.Timer.stamp();
    var delta = (now - last) * 1000;
    
    if (delta < 1)
      return;

    // trace(runnables.length, delta);
    last = now;

    for (i => r in runnables)
      running[i] = r.advance(delta);

    var deleted = 0;

    for (i => r in runnables)
      if (running[i]) deleted++;
      else runnables[i - deleted] = r;

    if (deleted > 0) {
      runnables.resize(runnables.length - deleted);
      running.resize(runnables.length);
      if (running.length == 0)
        stop();
    }
  }

  function start() {
    last = haxe.Timer.stamp();
    this.stop = schedule(advance);
  }

  var stop:()->Void;

  public function add(r:Runnable) {
    runnables.push(r);
    running.push(true);
    if (running.length == 1)
      start();
  }

  static public var DEFAULT = new Runner(run -> {
    #if js
      if (js.Lib.typeof(untyped requestAnimationFrame) != 'undefined') {
        var running = true;
        function tick(_) if (running) {
          run();
          js.Browser.window.requestAnimationFrame(tick);
        }
        run();
        js.Browser.window.requestAnimationFrame(tick);
        return () -> running = false;
      }
    #end
    var timer = new haxe.Timer(16);
    timer.run = run;
    timer.stop;
  });
  
}

interface Runnable {
  @:allow(tink.springs)
  private function advance(dt:Float):Bool;
}