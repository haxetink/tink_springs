package tink.springs;

import haxe.macro.Context;

using haxe.macro.Tools;

class SpringConfig {
  static function build() {
    var ret = Context.getBuildFields(),
        apply = [];

    for (f in Context.getType('tink.springs.Spring.SpringObject').getClass().fields.get())
      if (f.kind.match(FVar(_)) && !f.isFinal && !f.meta.has(':unconfigurable')) {

        var isFloat = Context.follow(f.type).match(TAbstract(_.get() => { pack: [], name: 'Float' }, _));
        ret.push({
          name: f.name,
          pos: f.pos,
          access: [APublic, AFinal],
          kind: FVar(
            f.type.toComplexType(),
            if (f.expr() == null) null else if (isFloat) macro Math.NaN else macro null
          )
        });

        var name = f.name;

        var check =
          if (isFloat)
            macro Math.isNaN($i{name});
          else
            macro $i{name} == null;

        apply.push(macro {
          var $name = this.$name;
          if (!($check)) spring.$name = $i{name};
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