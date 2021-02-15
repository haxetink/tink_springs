
import tink.geom2.*;
import tink.state.State;
import tink.state.Observable;
import tink.springs.Spring;
import js.html.*;
import js.Browser.*;

using tink.CoreApi;

class Playground {
  static function main() {
    setStyle();
    dragging();
    // balls();
  }
  static function setStyle() {
    var style = document.createStyleElement();
    style.textContent = '
      html, body {
        width: 100%;
        height: 100%;
        overflow: hidden;
        background: black;
      }
      * {
        margin: 0;
        padding: 0;
      }
    ';
    document.head.appendChild(style);
  }

  static function dragging() {
    function measure():Rect
      return document.body.getBoundingClientRect();

    final bounds = new State(measure());

    window.onresize = () -> bounds.set(measure());

    final panX = new Spring({ to: 0, getMin: () -> -bounds.value.width / 4, getMax: () -> bounds.value.width / 4 }),
          panY = new Spring({ to: 0, getMin: () -> -bounds.value.height / 10, getMax: () -> bounds.value.height / 10 }),
          zoom = new Spring(1);

    final transform = Observable.auto(() -> new PanZoom(panX, panY, zoom));

    function setTransform(p:PanZoom, ?immediate) {
      panX.set({ to: p.panX, immediate: immediate });
      panY.set({ to: p.panY, immediate: immediate });
      zoom.set({ to: p.zoom, immediate: immediate });
    }

    var rect = document.createElement('div');
    rect.style.cssText = '
      background-image: url("https://images.unsplash.com/photo-1470290449668-02dd93d9420a?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1500&q=80");
      background-size: cover;
      width: 50vw;
      height: 80vh;
      margin-top: 10vh;
      margin-left: 25vw;
    ';

    window.onwheel = function (e:WheelEvent) {
      var center = new Point(e.clientX - bounds.value.width / 2, e.clientY - bounds.value.height / 2);

      center = center * !transform.value;

      var factor = Math.pow(10, -e.deltaY / 500);

      setTransform((PanZoom.pan(-center) * factor + center) * transform.value, true);
    }

    document.body.appendChild(rect);

    Observable.autorun(() -> {
      rect.style.transform = transform.value;
    });


    var moved = {
      var trigger = new SignalTrigger();
      var last = null;

      function pos(e:MouseEvent)
        return new Point(e.clientX, e.clientY);

      function onmove(e:MouseEvent) {
        if (last == null) {
          last = pos(e);
          return;
        }
        final next = pos(e);
        final delta = next - last;
        last = next;
        trigger.trigger(delta);
      }

      window.addEventListener('mousemove', onmove);

      trigger.asSignal();
    }

    var xMoved = moved.map(p -> p.x),
        yMoved = moved.map(p -> p.y);

    rect.onmousedown = function (e) {
      window.onmouseup =
        panX.startDrag(xMoved)
          .join(panY.startDrag(yMoved));

    }

  }

  static function balls() {

    var w = window.innerWidth,
        h = window.innerHeight;

    var springs = [for (i in 0...1000) {
      var x = new Spring(Math.random() * w),
          y = new Spring(Math.random() * h);
      var transform = Observable.auto(() -> 'translate(${x.value}px, ${y.value}px)');
      { x: x, y: y, transform: transform };
    }];

    for (s in springs) {
      var ball = document.createDivElement();
      var size = Math.random() * 10 + 5;

      ball.style.cssText = '
        background: #00${StringTools.hex(30 + Std.random(0x100 - 30), 2)}00;
        width: ${size}px;
        height: ${size}px;
        border-radius: 100px;
        position: absolute;
        margin-top: ${-size / 2}px;
        margin-left: ${-size /2 }px
      ';

      s.transform.bind(t -> ball.style.transform = t);
      document.body.appendChild(ball);
    }

    function disperse()
      for (s in springs) {
        s.x.set(Math.random() * w);
        s.y.set(Math.random() * h);
      }

    function collect(e:MouseEvent)
      for (s in springs) {
        var angle = Math.random() * Math.PI * 2;
        var dist = Math.sqrt(Math.random()) * 100;
        s.x.set(e.clientX + Math.sin(angle) * dist);
        s.y.set(e.clientY + Math.cos(angle) * dist);
      }

    window.onmousedown = collect;
    window.onmousemove = (e:MouseEvent) -> {
      if (e.buttons > 0) collect(e);
    }
    window.onmouseup = disperse;

    window.onresize = () -> {
      w = window.innerWidth;
      h = window.innerHeight;
      disperse();
    }
  }
}