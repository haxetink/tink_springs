import tink.state.Observable;
import tink.springs.Spring;
import js.html.*;
import js.Browser.*;

class Playground {
  static function main() {
    {
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
        background: #00${StringTools.hex(Std.random(0x100), 2)}00; 
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