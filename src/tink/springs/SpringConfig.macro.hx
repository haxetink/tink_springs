package tink.springs;

import haxe.macro.Context;

using haxe.macro.Tools;

class SpringConfig {
  static function build() {
    var ret = Context.getBuildFields(),
        apply = [];

    for (f in Context.getType('tink.springs.Spring.SpringObject').getClass().fields.get())
      if (f.kind.match(FVar(_)) && !f.isFinal && !f.meta.has(':unconfigurable')) {

        ret.push({
          name: f.name,
          pos: f.pos,
          access: [APublic, AFinal],
          kind: FVar(
            f.type.toComplexType(),
            if (f.expr() == null) null else macro Math.NaN
          )
        });

        apply.push({
          var name = f.name;
          macro {
            var $name = this.$name;
            if (!Math.isNaN($i{name})) spring.$name = $i{name};
          }
        });
      }

    return ret.concat(
      (macro class {
        inline function setNumbers(spring:Spring.SpringObject)
          $b{apply}
      }).fields
    );
  }
}