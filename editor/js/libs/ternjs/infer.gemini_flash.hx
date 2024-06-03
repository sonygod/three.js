package tern.infer;

import tern.def;
import tern.signal;

class ANull {
  public function addType(type:Type, weight:Int = 100):Void { }
  public function propagate(target:AVal, weight:Int = 100):Void { }
  public function getProp(prop:String):AVal { return ANull; }
  public function forAllProps(c:Dynamic):Void { }
  public function hasType(type:Type):Bool { return false; }
  public function isEmpty():Bool { return true; }
  public function getFunctionType():Fn { return null; }
  public function getObjType():Obj { return null; }
  public function getType(guess:Bool = true):Type { return null; }
  public function gatherProperties(f:Dynamic, depth:Int = 0):Void { }
  public function propagatesTo():Dynamic { return this; }
  public function typeHint():Type { return null; }
  public function propHint():String { return null; }
  public function toString(maxDepth:Null<Int> = null, parent:Type = null):String { return "?"; }
  public function computedPropType():Type { return null; }
  public function makeupType():Type { return null; }
  public function guessProperties(f:Dynamic):Void { }
  public function purge(test:Dynamic):Void { }
  public function purgeGen(gen:Int):Void { }
}

class AVal extends ANull {
  public var types:Array<Type> = [];
  public var forward:Array<AVal> = null;
  public var maxWeight:Int = 0;
  public var propertyOf:Obj = null;
  public var props:Map<String, AVal> = null;
  public var purgeGen:Int = 0;

  public function new() {
    super();
    signal.mixin(this);
  }

  public function addType(type:Type, weight:Int = 100):Void {
    weight = weight || WG_DEFAULT;
    if (this.maxWeight < weight) {
      this.maxWeight = weight;
      if (this.types.length == 1 && this.types[0] == type) return;
      this.types.length = 0;
    } else if (this.maxWeight > weight || this.types.indexOf(type) > -1) {
      return;
    }

    this.signal("addType", type);
    this.types.push(type);
    var forward = this.forward;
    if (forward != null) {
      withWorklist(function(add) {
        for (var i = 0; i < forward.length; ++i) {
          add(type, forward[i], weight);
        }
      });
    }
  }

  public function propagate(target:AVal, weight:Int = 100):Void {
    if (target == ANull || (target is Type && this.forward != null && this.forward.length > 2)) return;
    if (weight != null && weight != WG_DEFAULT) {
      target = new Muffle(target, weight);
    }
    if (this.forward == null) {
      this.forward = [];
    }
    this.forward.push(target);
    var types = this.types;
    if (types.length > 0) {
      withWorklist(function(add) {
        for (var i = 0; i < types.length; ++i) {
          add(types[i], target, weight);
        }
      });
    }
  }

  public function getProp(prop:String):AVal {
    if (prop == "__proto__" || prop == "✖") return ANull;
    var found = (this.props || (this.props = new Map<String, AVal>()))[prop];
    if (found == null) {
      found = this.props[prop] = new AVal();
      this.propagate(new PropIsSubset(prop, found));
    }
    return found;
  }

  public function forAllProps(c:Dynamic):Void {
    this.propagate(new ForAllProps(c));
  }

  public function hasType(type:Type):Bool {
    return this.types.indexOf(type) > -1;
  }

  public function isEmpty():Bool {
    return this.types.length == 0;
  }

  public function getFunctionType():Fn {
    for (var i = this.types.length - 1; i >= 0; --i) {
      if (this.types[i] is Fn) {
        return this.types[i];
      }
    }
    return null;
  }

  public function getObjType():Obj {
    var seen:Obj = null;
    for (var i = this.types.length - 1; i >= 0; --i) {
      var type = this.types[i];
      if (!(type is Obj)) continue;
      if (type.name != null) return type;
      if (seen == null) seen = type;
    }
    return seen;
  }

  public function getType(guess:Bool = true):Type {
    if (this.types.length == 0 && guess) {
      return this.makeupType();
    }
    if (this.types.length == 1) {
      return this.types[0];
    }
    return canonicalType(this.types);
  }

  public function toString(maxDepth:Null<Int> = null, parent:Type = null):String {
    if (this.types.length == 0) {
      return toString(this.makeupType(), maxDepth, parent);
    }
    if (this.types.length == 1) {
      return toString(this.types[0], maxDepth, parent);
    }
    var simplified = simplifyTypes(this.types);
    if (simplified.length > 2) {
      return "?";
    }
    return simplified.map(function(tp) { return toString(tp, maxDepth, parent); }).join("|");
  }

  public function computedPropType():Type {
    if (this.propertyOf == null) {
      return null;
    }
    if (this.propertyOf.hasProp("<i>")) {
      var computedProp = this.propertyOf.getProp("<i>");
      if (computedProp == this) {
        return null;
      }
      return computedProp.getType();
    } else if (this.propertyOf.maybeProps != null && this.propertyOf.maybeProps["<i>"] == this) {
      for (var prop in this.propertyOf.props) {
        var val = this.propertyOf.props[prop];
        if (!val.isEmpty()) {
          return val;
        }
      }
      return null;
    }
    return null;
  }

  public function makeupType():Type {
    var computed = this.computedPropType();
    if (computed != null) return computed;

    if (this.forward == null) return null;
    for (var i = this.forward.length - 1; i >= 0; --i) {
      var hint = this.forward[i].typeHint();
      if (hint != null && !hint.isEmpty()) {
        guessing = true;
        return hint;
      }
    }

    var props = new Map<String, Bool>();
    var foundProp:String = null;
    for (var i = 0; i < this.forward.length; ++i) {
      var prop = this.forward[i].propHint();
      if (prop != null && prop != "length" && prop != "<i>" && prop != "✖" && prop != cx.completingProperty) {
        props[prop] = true;
        foundProp = prop;
      }
    }
    if (foundProp == null) {
      return null;
    }

    var objs = objsWithProp(foundProp);
    if (objs != null) {
      var matches = [];
      for (var i = 0; i < objs.length; ++i) {
        var obj = objs[i];
        for (var prop in props) {
          if (!obj.hasProp(prop)) continue;
        }
        if (obj.hasCtor != null) obj = getInstance(obj);
        matches.push(obj);
      }
      var canon = canonicalType(matches);
      if (canon != null) {
        guessing = true;
        return canon;
      }
    }
    return null;
  }

  public function typeHint():Type {
    return this.types.length > 0 ? this.getType() : null;
  }

  public function propagatesTo():Dynamic {
    return this;
  }

  public function gatherProperties(f:Dynamic, depth:Int = 0):Void {
    for (var i = 0; i < this.types.length; ++i) {
      this.types[i].gatherProperties(f, depth);
    }
  }

  public function guessProperties(f:Dynamic):Void {
    if (this.forward != null) {
      for (var i = 0; i < this.forward.length; ++i) {
        var prop = this.forward[i].propHint();
        if (prop != null) f(prop, null, 0);
      }
    }
    var guessed = this.makeupType();
    if (guessed != null) guessed.gatherProperties(f);
  }

  public function purge(test:Dynamic):Void {
    if (this.purgeGen == cx.purgeGen) return;
    this.purgeGen = cx.purgeGen;
    for (var i = 0; i < this.types.length; ++i) {
      var type = this.types[i];
      if (test(type, type.originNode)) {
        this.types.splice(i--, 1);
      } else {
        type.purge(test);
      }
    }
    if (this.forward != null) {
      for (var i = 0; i < this.forward.length; ++i) {
        var f = this.forward[i];
        if (test(f)) {
          this.forward.splice(i--, 1);
          if (this.props != null) this.props = null;
        } else if (f.purge != null) {
          f.purge(test);
        }
      }
    }
  }
}

class Constraint extends ANull {
  public var origin:String;
  public var originNode:Dynamic;
  public var disabled:DisabledComputing = null;

  public function new() {
    super();
    this.init();
  }

  public function init():Void {
    this.origin = cx.curOrigin;
  }

  public function propagatesTo():Dynamic {
    return null;
  }

  public function propHint():String {
    return null;
  }
}

class PropIsSubset extends Constraint {
  public var prop:String;
  public var target:AVal;

  public function new(prop:String, target:AVal) {
    super();
    this.prop = prop;
    this.target = target;
  }

  public function addType(type:Type, weight:Int = 100):Void {
    if (type.getProp != null) {
      type.getProp(this.prop).propagate(this.target, weight);
    }
  }

  public function propHint():String {
    return this.prop;
  }

  public function propagatesTo():Dynamic {
    if (this.prop == "<i>" || !/[^\w_]/.test(this.prop)) {
      return {target: this.target, pathExt: "." + this.prop};
    }
    return null;
  }
}

class PropHasSubset extends Constraint {
  public var prop:String;
  public var type:AVal;
  public var originNode:Dynamic;

  public function new(prop:String, type:AVal, originNode:Dynamic) {
    super();
    this.prop = prop;
    this.type = type;
    this.originNode = originNode;
  }

  public function addType(type:Type, weight:Int = 100):Void {
    if (!(type is Obj)) {
      return;
    }
    var prop = type.defProp(this.prop, this.originNode);
    if (prop.origin == null) {
      prop.origin = this.origin;
    }
    this.type.propagate(prop, weight);
  }

  public function propHint():String {
    return this.prop;
  }
}

class ForAllProps extends Constraint {
  public var c:Dynamic;

  public function new(c:Dynamic) {
    super();
    this.c = c;
  }

  public function addType(type:Type, weight:Int = 100):Void {
    if (!(type is Obj)) {
      return;
    }
    type.forAllProps(this.c);
  }
}

class IsCallee extends Constraint {
  public var self:AVal;
  public var args:Array<AVal>;
  public var argNodes:Array<Dynamic>;
  public var retval:AVal;

  public function new(self:AVal, args:Array<AVal>, argNodes:Array<Dynamic>, retval:AVal) {
    super();
    this.self = self;
    this.args = args;
    this.argNodes = argNodes;
    this.retval = retval;
  }

  public function addType(fn:Type, weight:Int = 100):Void {
    if (!(fn is Fn)) return;
    for (var i = 0; i < this.args.length; ++i) {
      if (i < fn.args.length) {
        this.args[i].propagate(fn.args[i], weight);
      }
      if (fn.arguments != null) {
        this.args[i].propagate(fn.arguments, weight);
      }
    }
    this.self.propagate(fn.self, this.self == cx.topScope ? WG_GLOBAL_THIS : weight);
    var compute = fn.computeRet;
    if (compute != null) {
      for (var d = this.disabled; d != null; d = d.prev) {
        if (d.fn == fn || (fn.originNode != null && d.fn.originNode == fn.originNode)) {
          compute = null;
        }
      }
    }
    if (compute != null) {
      compute(this.self, this.args, this.argNodes).propagate(this.retval, weight);
    } else {
      fn.retval.propagate(this.retval, weight);
    }
  }

  public function typeHint():Type {
    var names = [];
    for (var i = 0; i < this.args.length; ++i) {
      names.push("?");
    }
    return new Fn(null, this.self, this.args, names, ANull);
  }

  public function propagatesTo():Dynamic {
    return {target: this.retval, pathExt: ".!ret"};
  }
}

class HasMethodCall extends Constraint {
  public var propName:String;
  public var args:Array<AVal>;
  public var argNodes:Array<Dynamic>;
  public var retval:AVal;

  public function new(propName:String, args:Array<AVal>, argNodes:Array<Dynamic>, retval:AVal) {
    super();
    this.propName = propName;
    this.args = args;
    this.argNodes = argNodes;
    this.retval = retval;
  }

  public function addType(obj:Type, weight:Int = 100):Void {
    var callee = new IsCallee(obj, this.args, this.argNodes, this.retval);
    callee.disabled = this.disabled;
    obj.getProp(this.propName).propagate(callee, weight);
  }

  public function propHint():String {
    return this.propName;
  }
}

class IsCtor extends Constraint {
  public var target:AVal;
  public var noReuse:Bool;

  public function new(target:AVal, noReuse:Bool) {
    super();
    this.target = target;
    this.noReuse = noReuse;
  }

  public function addType(f:Type, weight:Int = 100):Void {
    if (!(f is Fn)) return;
    if (cx.parent != null && !cx.parent.options.reuseInstances) {
      this.noReuse = true;
    }
    f.getProp("prototype").propagate(new IsProto(this.noReuse ? false : f, this.target), weight);
  }
}

class IsProto extends Constraint {
  public var ctor:Fn;
  public var target:AVal;
  public var count:Int = 0;

  public function new(ctor:Fn, target:AVal) {
    super();
    this.ctor = ctor;
    this.target = target;
  }

  public function addType(o:Type, _weight:Int = 100):Void {
    if (!(o is Obj)) return;
    this.count = (this.count || 0) + 1;
    if (this.count > 8) return;
    if (o == cx.protos.Array) {
      this.target.addType(new Arr());
    } else {
      this.target.addType(getInstance(o, this.ctor));
    }
  }
}

class FnPrototype extends Constraint {
  public var fn:Fn;

  public function new(fn:Fn) {
    super();
    this.fn = fn;
  }

  public function addType(o:Type, _weight:Int = 100):Void {
    if (o is Obj && o.hasCtor == null) {
      o.hasCtor = this.fn;
      var adder = new SpeculativeThis(o, this.fn);
      adder.addType(this.fn);
      o.forAllProps(function(_prop:String, val:AVal, local:Bool) {
        if (local) {
          val.propagate(adder);
        }
      });
    }
  }
}

class IsAdded extends Constraint {
  public var other:AVal;
  public var target:AVal;

  public function new(other:AVal, target:AVal) {
    super();
    this.other = other;
    this.target = target;
  }

  public function addType(type:Type, weight:Int = 100):Void {
    if (type == cx.str) {
      this.target.addType(cx.str, weight);
    } else if (type == cx.num && this.other.hasType(cx.num)) {
      this.target.addType(cx.num, weight);
    }
  }

  public function typeHint():Type {
    return this.other;
  }
}

class IfObj extends Constraint {
  public var target:AVal;

  public function new(target:AVal) {
    super();
    this.target = target;
  }

  public function addType(t:Type, weight:Int = 100):Void {
    if (t is Obj) {
      this.target.addType(t, weight);
    }
  }

  public function propagatesTo():Dynamic {
    return this.target;
  }
}

class SpeculativeThis extends Constraint {
  public var obj:Obj;
  public var ctor:Fn;

  public function new(obj:Obj, ctor:Fn) {
    super();
    this.obj = obj;
    this.ctor = ctor;
  }

  public function addType(tp:Type, weight:Int = 100):Void {
    if (tp is Fn && tp.self != null && tp.self.isEmpty()) {
      tp.self.addType(getInstance(this.obj, this.ctor), WG_SPECULATIVE_THIS);
    }
  }
}

class Muffle extends Constraint {
  public var inner:AVal;
  public var weight:Int;

  public function new(inner:AVal, weight:Int) {
    super();
    this.inner = inner;
    this.weight = weight;
  }

  public function addType(tp:Type, weight:Int = 100):Void {
    this.inner.addType(tp, Math.min(weight, this.weight));
  }

  public function propagatesTo():Dynamic {
    return this.inner.propagatesTo();
  }

  public function typeHint():Type {
    return this.inner.typeHint();
  }

  public function propHint():String {
    return this.inner.propHint();
  }
}

class Type extends ANull {
  public var origin:String;
  public var originNode:Dynamic;
  public var purgeGen:Int = 0;

  public function new() {
    super();
    signal.mixin(this);
  }

  public function propagate(c:Constraint, w:Int = 100):Void {
    c.addType(this, w);
  }

  public function hasType(other:Type):Bool {
    return other == this;
  }

  public function isEmpty():Bool {
    return false;
  }

  public function typeHint():Type {
    return this;
  }

  public function getType():Type {
    return this;
  }

  public function gatherProperties(f:Dynamic, depth:Int = 0):Void { }

  public function purge(test:Dynamic):Void {
    if (this.purgeGen == cx.purgeGen) return;
    this.purgeGen = cx.purgeGen;
  }
}

class Prim extends Type {
  public var name:String;
  public var proto:Obj;

  public function new(proto:Obj, name:String) {
    super();
    this.name = name;
    this.proto = proto;
  }

  public function toString():String {
    return this.name;
  }

  public function getProp(prop:String):AVal {
    return this.proto.hasProp(prop) || ANull;
  }

  public function gatherProperties(f:Dynamic, depth:Int = 0):Void {
    if (this.proto != null) {
      this.proto.gatherProperties(f, depth);
    }
  }

  public function purge(test:Dynamic):Void {
    super.purge(test);
    if (this.proto != null) {
      this.proto.purge(test);
    }
  }
}

class Obj extends Type {
  public var proto:Obj;
  public var name:String;
  public var props:Map<String, AVal> = null;
  public var maybeProps:Map<String, AVal> = null;
  public var instances:Array<{ctor:Fn, instance:Obj}> = null;
  public var onNewProp:Array<Dynamic> = null;
  public var hasCtor:Fn = null;
  public var instantiateScore:Int = 0;

  public function new(proto:Dynamic, name:String = null) {
    super();
    if (this.props == null) {
      this.props = new Map<String, AVal>();
    }
    this.proto = proto == true ? cx.protos.Object : proto;
    if (proto != null && name == null && proto.name != null && !(this is Fn)) {
      var match = /^(.*)\.prototype$/.exec(this.proto.name);
      if (match != null) {
        name = match[1];
      }
    }
    this.name = name;
    signal.mixin(this);
  }

  public function toString(maxDepth:Null<Int> = null):String {
    if (maxDepth == null) {
      maxDepth = 0;
    }
    if (maxDepth <= 0 && this.name != null) {
      return this.name;
    }
    var props = [], etc = false;
    for (var prop in this.props) {
      if (prop == "<i>") {
        continue;
      }
      if (props.length > 5) {
        etc = true;
        break;
      }
      if (maxDepth != null) {
        props.push(prop + ": " + toString(this.props[prop], maxDepth - 1, this));
      } else {
        props.push(prop);
      }
    }
    props.sort();
    if (etc) {
      props.push("...");
    }
    return "{" + props.join(", ") + "}";
  }

  public function hasProp(prop:String, searchProto:Bool = true):AVal {
    var found = this.props[prop];
    if (searchProto) {
      for (var p = this.proto; p != null && found == null; p = p.proto) {
        found = p.props[prop];
      }
    }
    return found;
  }

  public function defProp(prop:String, originNode:Dynamic):AVal {
    var found = this.hasProp(prop, false);
    if (found != null) {
      if (originNode != null && found.originNode == null) {
        found.originNode = originNode;
      }
      return found;
    }
    if (prop == "__proto__" || prop == "✖") return ANull;

    var av = this.maybeProps != null ? this.maybeProps[prop] : null;
    if (av != null) {
      delete this.maybeProps[prop];
      this.maybeUnregProtoPropHandler();
    } else {
      av = new AVal();
      av.propertyOf = this;
    }

    this.props[prop] = av;
    av.originNode = originNode;
    av.origin = cx.curOrigin;
    this.broadcastProp(prop, av, true);
    return av;
  }

  public function getProp(prop:String):AVal {
    var found = this.hasProp(prop, true) || (this.maybeProps != null ? this.maybeProps[prop] : null);
    if (found != null) {
      return found;
    }
    if (prop == "__proto__" || prop == "✖") return ANull;
    var av = this.ensureMaybeProps()[prop] = new AVal();
    av.propertyOf = this;
    return av;
  }

  public function broadcastProp(prop:String, val:AVal, local:Bool):Void {
    if (local) {
      this.signal("addProp", prop, val);
      // If this is a scope, it shouldn't be registered
      if (!(this is Scope)) {
        registerProp(prop, this);
      }
    }

    if (this.onNewProp != null) {
      for (var i = 0; i < this.onNewProp.length; ++i) {
        var h = this.onNewProp[i];
        if (h.onProtoProp != null) {
          h.onProtoProp(prop, val, local);
        } else {
          h(prop, val, local);
        }
      }
    }
  }

  public function onProtoProp(prop:String, val:AVal, _local:Bool):Void {
    var maybe = this.maybeProps != null ? this.maybeProps[prop] : null;
    if (maybe != null) {
      delete this.maybeProps[prop];
      this.maybeUnregProtoPropHandler();
      this.proto.getProp(prop).propagate(maybe);
    }
    this.broadcastProp(prop, val, false);
  }

  public function ensureMaybeProps():Map<String, AVal> {
    if (this.maybeProps == null) {
      if (this.proto != null) {
        this.proto.forAllProps(this);
      }
      this.maybeProps = new Map<String, AVal>();
    }
    return this.maybeProps;
  }

  public function removeProp(prop:String):Void {
    var av = this.props[prop];
    delete this.props[prop];
    this.ensureMaybeProps()[prop] = av;
    av.types.length = 0;
  }

  public function forAllProps(c:Dynamic):Void {
    if (this.onNewProp == null) {
      this.onNewProp = [];
      if (this.proto != null) {
        this.proto.forAllProps(this);
      }
    }
    this.onNewProp.push(c);
    for (var o = this; o != null; o = o.proto) {
      for (var prop in o.props) {
        if (c.onProtoProp != null) {
          c.onProtoProp(prop, o.props[prop], o == this);
        } else {
          c(prop, o.props[prop], o == this);
        }
      }
    }
  }

  public function maybeUnregProtoPropHandler():Void {
    if (this.maybeProps != null) {
      for (var _n in this.maybeProps) {
        return;
      }
      this.maybeProps = null;
    }
    if (this.proto == null || (this.onNewProp != null && this.onNewProp.length > 0)) {
      return;
    }
    this.proto.unregPropHandler(this);
  }

  public function unregPropHandler(handler:Dynamic):Void {
    for (var i = 0; i < this.onNewProp.length; ++i) {
      if (this.onNewProp[i] == handler) {
        this.onNewProp.splice(i, 1);
        break;
      }
    }
    this.maybeUnregProtoPropHandler();
  }

  public function gatherProperties(f:Dynamic, depth:Int = 0):Void {
    for (var prop in this.props) {
      if (prop == "<i>") {
        continue;
      }
      f(prop, this, depth);
    }
    if (this.proto != null) {
      this.proto.gatherProperties(f, depth + 1);
    }
  }

  public function getObjType():Obj {
    return this;
  }

  public function purge(test:Dynamic):Void {
    if (this.purgeGen == cx.purgeGen) return;
    this.purgeGen = cx.purgeGen;
    for (var p in this.props) {
      var av = this.props[p];
      if (test(av, av.originNode)) {
        this.removeProp(p);
      }
      av.purge(test);
    }
  }
}

class Fn extends Obj {
  public var self:AVal;
  public var args:Array<AVal>;
  public var argNames:Array<String>;
  public var retval:AVal;
  public var arguments:AVal;
  public var computeRet:Dynamic = null;
  public var computeRetSource:String = null;

  public function new(name:String, self:AVal, args:Array<AVal>, argNames:Array<String>, retval:AVal) {
    super(cx.protos.Function, name);
    this.self = self;
    this.args = args;
    this.argNames = argNames;
    this.retval = retval;
  }

  public function toString(maxDepth:Null<Int> = null):String {
    if (maxDepth == null) {
      maxDepth = 0;
    }
    var str = "fn(";
    for (var i = 0; i < this.args.length; ++i) {
      if (i > 0) {
        str += ", ";
      }
      var name = this.argNames[i];
      if (name != null && name != "?") {
        str += name + ": ";
      }
      str += maxDepth > -3 ? toString(this.args[i], maxDepth - 1, this) : "?";
    }
    str += ")";
    if (!this.retval.isEmpty()) {
      str += " -> " + (maxDepth > -3 ? toString(this.retval, maxDepth - 1, this) : "?");
    }
    return str;
  }

  public function getProp(prop:String):AVal {
    if (prop == "prototype") {
      var known = this.hasProp(prop, false);
      if (known == null) {
        known = this.defProp(prop);
        var proto = new Obj(true, this.name != null ? this.name + ".prototype" : null);
        proto.origin = this.origin;
        known.addType(proto, WG_MADEUP_PROTO);
      }
      return known;
    }
    return super.getProp(prop);
  }

  public function defProp(prop:String, originNode:Dynamic):AVal {
    if (prop == "prototype") {
      var found = this.hasProp(prop, false);
      if (found != null) return found;
      found = super.defProp(prop, originNode);
      found.origin = this.origin;
      found.propagate(new FnPrototype(this));
      return found;
    }
    return super.defProp(prop, originNode);
  }

  public function getFunctionType():Fn {
    return this;
  }

  public function purge(test:Dynamic):Void {
    if (super.purge(test)) return;
    this.self.purge(test);
    this.retval.purge(test);
    for (var i = 0; i < this.args.length; ++i) {
      this.args[i].purge(test);
    }
  }
}

class Arr extends Obj {
  public function new(contentType:AVal = null) {
    super(cx.protos.Array);
    var content = this.defProp("<i>");
    if (contentType != null) {

      contentType.propagate(content);
    }
  }

  public function toString(maxDepth:Null<Int> = null):String {
    if (maxDepth == null) maxDepth = 0;
    return "[" + (maxDepth > -3 ? toString(this.getProp("<i>"), maxDepth - 1, this) : "?") + "]";
  }

  public function purge(test:Dynamic):Void {
    if (super.purge(test)) return;
    this.getProp("<i>").purge(test);
  }
}

// THE PROPERTY REGISTRY

function registerProp(prop:String, obj:Obj):Void {
  var data = cx.props[prop] || (cx.props[prop] = new Array<Obj>());
  data.push(obj);
}

function objsWithProp(prop:String):Array<Obj> {
  return cx.props[prop];
}

// INFERENCE CONTEXT

class Context {
  public var parent:Context;
  public var props:Map<String, Array<Obj>> = null;
  public var protos:Map<String, Obj> = null;
  public var origins:Array<String> = null;
  public var curOrigin:String;
  public var paths:Map<String, Dynamic> = null;
  public var definitions:Map<String, Dynamic> = null;
  public var purgeGen:Int = 0;
  public var workList:Worklist = null;
  public var disabledComputing:DisabledComputing = null;
  public var completingProperty:String = null;
  public var options:Options = null;

  public function new(defs:Array<Dynamic>, parent:Context) {
    this.parent = parent;
    this.props = new Map<String, Array<Obj>>();
    this.protos = new Map<String, Obj>();
    this.origins = [];
    this.curOrigin = "ecma5";
    this.paths = new Map<String, Dynamic>();
    this.definitions = new Map<String, Dynamic>();
    this.options = new Options();
    withContext(this, function() {
      cx.protos.Object = new Obj(null, "Object.prototype");
      cx.topScope = new Scope();
      cx.topScope.name = "<top>";
      cx.protos.Array = new Obj(true, "Array.prototype");
      cx.protos.Function = new Obj(true, "Function.prototype");
      cx.protos.RegExp = new Obj(true, "RegExp.prototype");
      cx.protos.String = new Obj(true, "String.prototype");
      cx.protos.Number = new Obj(true, "Number.prototype");
      cx.protos.Boolean = new Obj(true, "Boolean.prototype");
      cx.str = new Prim(cx.protos.String, "string");
      cx.bool = new Prim(cx.protos.Boolean, "bool");
      cx.num = new Prim(cx.protos.Number, "number");
      cx.curOrigin = null;

      if (defs != null) {
        for (var i = 0; i < defs.length; ++i) {
          def.load(defs[i]);
        }
      }
    });
  }
}

class DisabledComputing {
  public var fn:Fn;
  public var prev:DisabledComputing;

  public function new(fn:Fn, prev:DisabledComputing) {
    this.fn = fn;
    this.prev = prev;
  }
}

var cx:Context = null;
function cx():Context {
  return cx;
}

function withContext(context:Context, f:Dynamic):Dynamic {
  var old = cx;
  cx = context;
  try {
    return f();
  } finally {
    cx = old;
  }
}

class TimedOut extends Error {
  public function new() {
    super("Timed out");
    this.stack = (new Error()).stack;
  }
}

var timeout:Int = null;
function withTimeout(ms:Int, f:Dynamic):Dynamic {
  var end = new Date().getTime() + ms;
  var oldEnd = timeout;
  if (oldEnd != null && oldEnd < end) return f();
  timeout = end;
  try { return f(); }
  finally { timeout = oldEnd; }
}

function addOrigin(origin:String):Void {
  if (cx.origins.indexOf(origin) < 0) {
    cx.origins.push(origin);
  }
}

var baseMaxWorkDepth:Int = 20;
var reduceMaxWorkDepth:Float = 0.0001;
typedef Worklist = Dynamic->Void;

function withWorklist(f:Worklist->Dynamic):Dynamic {
  if (cx.workList != null) return f(cx.workList);

  var list:Array<Dynamic> = [], depth:Int = 0;
  var add:Worklist = cx.workList = function(type:Type, target:AVal, weight:Int) {
    if (depth < baseMaxWorkDepth - reduceMaxWorkDepth * list.length) {
      list.push(type, target, weight, depth);
    }
  };
  try {
    var ret = f(add);
    for (var i = 0; i < list.length; i += 4) {
      if (timeout != null && new Date().getTime() >= timeout) {
        throw new TimedOut();
      }
      depth = list[i + 3] + 1;
      list[i + 1].addType(list[i], list[i + 2]);
    }
    return ret;
  } finally {
    cx.workList = null;
  }
}

// SCOPES

class Scope extends Obj {
  public var prev:Scope;
  public var fnType:Fn = null;
  public var originNode:Dynamic = null;
  public var iteratesOver:AVal = null;

  public function new(prev:Scope = null) {
    super(prev || true);
    this.prev = prev;
  }

  public function defVar(name:String, originNode:Dynamic):AVal {
    for (var s = this; true; s = s.proto) {
      var found = s.props[name];
      if (found != null) return found;
      if (s.prev == null) return s.defProp(name, originNode);
    }
  }

  public function purge(test:Dynamic):Void {
    if (super.purge(test)) return;
    if (this.fnType != null) {
      this.fnType.purge(test);
    }
    if (this.prev != null) {
      this.prev.purge(test);
    }
  }
}

// RETVAL COMPUTATION HEURISTICS

function maybeInstantiate(scope:Scope, score:Float):Void {
  if (scope.fnType != null) {
    scope.fnType.instantiateScore = (scope.fnType.instantiateScore || 0) + score;
  }
}

var NotSmaller = {};

function nodeSmallerThan(node:Dynamic, n:Int):Bool {
  try {
    walk.simple(node, {
      Expression: function() {
        if (--n <= 0) throw NotSmaller;
      }
    });
    return true;
  } catch(e) {
    if (e == NotSmaller) return false;
    throw e;
  }
}

function maybeTagAsInstantiated(node:Dynamic, scope:Scope):Bool {
  var score = scope.fnType.instantiateScore;
  if (cx.disabledComputing == null && score != null && scope.fnType.args.length > 0 && nodeSmallerThan(node, score * 5)) {
    maybeInstantiate(scope.prev, score / 2);
    setFunctionInstantiated(node, scope);
    return true;
  } else {
    scope.fnType.instantiateScore = null;
  }
  return false;
}

function setFunctionInstantiated(node:Dynamic, scope:Scope):Void {
  var fn = scope.fnType;
  // Disconnect the arg avals, so that we can add info to them without side effects
  for (var i = 0; i < fn.args.length; ++i) {
    fn.args[i] = new AVal();
  }
  fn.self = new AVal();
  fn.computeRet = function(self:AVal, args:Array<AVal>):AVal {
    // Prevent recursion
    return withDisabledComputing(fn, function() {
      var oldOrigin = cx.curOrigin;
      cx.curOrigin = fn.origin;
      var scopeCopy = new Scope(scope.prev);
      scopeCopy.originNode = scope.originNode;
      for (var v in scope.props) {
        var local = scopeCopy.defProp(v, scope.props[v].originNode);
        for (var i = 0; i < args.length; ++i) {
          if (fn.argNames[i] == v && i < args.length) {
            args[i].propagate(local);
          }
        }
      }
      var argNames = fn.argNames.length != args.length ? fn.argNames.slice(0, args.length) : fn.argNames;
      while (argNames.length < args.length) {
        argNames.push("?");
      }
      scopeCopy.fnType = new Fn(fn.name, self, args, argNames, ANull);
      scopeCopy.fnType.originNode = fn.originNode;
      if (fn.arguments != null) {
        var argset = scopeCopy.fnType.arguments = new AVal();
        scopeCopy.defProp("arguments").addType(new Arr(argset));
        for (var i = 0; i < args.length; ++i) {
          args[i].propagate(argset);
        }
      }
      node.body.scope = scopeCopy;
      walk.recursive(node.body, scopeCopy, null, scopeGatherer);
      walk.recursive(node.body, scopeCopy, null, inferWrapper);
      cx.curOrigin = oldOrigin;
      return scopeCopy.fnType.retval;
    });
  };
}

function maybeTagAsGeneric(scope:Scope):Bool {
  var fn = scope.fnType;
  var target = fn.retval;
  if (target == ANull) return false;
  var targetInner:Type, asArray:AVal;
  if (!target.isEmpty() && (targetInner = target.getType()) is Arr) {
    target = asArray = targetInner.getProp("<i>");
  }

  function explore(aval:AVal, path:String, depth:Int):String {
    if (depth > 3 || aval.forward == null) return null;
    for (var i = 0; i < aval.forward.length; ++i) {
      var prop = aval.forward[i].propagatesTo();
      if (prop == null) continue;
      var newPath = path, dest:AVal;
      if (prop is AVal) {
        dest = prop;
      } else if (prop.target is AVal) {
        newPath += prop.pathExt;
        dest = prop.target;
      } else {
        continue;
      }
      if (dest == target) {
        return newPath;
      }
      var found = explore(dest, newPath, depth + 1);
      if (found != null) return found;
    }
    return null;
  }

  var foundPath = explore(fn.self, "!this", 0);
  for (var i = 0; foundPath == null && i < fn.args.length; ++i) {
    foundPath = explore(fn.args[i], "!" + i, 0);
  }

  if (foundPath != null) {
    if (asArray != null) foundPath = "[" + foundPath + "]";
    var p = new def.TypeParser(foundPath);
    var parsed = p.parseType(true);
    fn.computeRet = parsed.apply != null ? parsed : function() { return parsed; };
    fn.computeRetSource = foundPath;
    return true;
  }
  return false;
}

// SCOPE GATHERING PASS

function addVar(scope:Scope, nameNode:Dynamic):AVal {
  return scope.defProp(nameNode.name, nameNode);
}

var scopeGatherer = walk.make({
  Function: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    var inner = node.body.scope = new Scope(scope);
    inner.originNode = node;
    var argVals = new Array<AVal>(), argNames = new Array<String>();
    for (var i = 0; i < node.params.length; ++i) {
      var param = node.params[i];
      argNames.push(param.name);
      argVals.push(addVar(inner, param));
    }
    inner.fnType = new Fn(node.id != null ? node.id.name : null, new AVal(), argVals, argNames, ANull);
    inner.fnType.originNode = node;
    if (node.id != null) {
      var decl = node.type == "FunctionDeclaration";
      addVar(decl ? scope : inner, node.id);
    }
    c(node.body, inner, "ScopeBody");
  },
  TryStatement: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    c(node.block, scope, "Statement");
    if (node.handler != null) {
      var v = addVar(scope, node.handler.param);
      c(node.handler.body, scope, "ScopeBody");
      var e5 = cx.definitions.ecma5;
      if (e5 != null && v.isEmpty()) {
        getInstance(e5["Error.prototype"]).propagate(v, WG_CATCH_ERROR);
      }
    }
    if (node.finalizer != null) {
      c(node.finalizer, scope, "Statement");
    }
  },
  VariableDeclaration: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    for (var i = 0; i < node.declarations.length; ++i) {
      var decl = node.declarations[i];
      addVar(scope, decl.id);
      if (decl.init != null) {
        c(decl.init, scope, "Expression");
      }
    }
  }
});

// CONSTRAINT GATHERING PASS

function propName(node:Dynamic, scope:Scope, c:Dynamic = null):String {
  var prop = node.property;
  if (!node.computed) return prop.name;
  if (prop.type == "Literal" && typeof prop.value == "string") return prop.value;
  if (c != null) infer(prop, scope, c, ANull);
  return "<i>";
}

function unopResultType(op:String):Type {
  switch (op) {
  case "+":
  case "-":
  case "~":
    return cx.num;
  case "!":
    return cx.bool;
  case "typeof":
    return cx.str;
  case "void":
  case "delete":
    return ANull;
  default:
    return null;
  }
}

function binopIsBoolean(op:String):Bool {
  switch (op) {
  case "==":
  case "!=":
  case "===":
  case "!==":
  case "<":
  case ">":
  case ">=":
  case "<=":
  case "in":
  case "instanceof":
    return true;
  default:
    return false;
  }
}

function literalType(node:Dynamic):Type {
  if (node.regex) return getInstance(cx.protos.RegExp);
  switch (typeof node.value) {
  case "boolean":
    return cx.bool;
  case "number":
    return cx.num;
  case "string":
    return cx.str;
  case "object":
  case "function":
    if (node.value == null) {
      return ANull;
    }
    return getInstance(cx.protos.RegExp);
  default:
    return null;
  }
}

typedef InferExpr = Dynamic->Scope->Dynamic->AVal->String->AVal;

function ret(f:InferExpr):InferExpr {
  return function(node:Dynamic, scope:Scope, c:Dynamic, out:AVal, name:String):AVal {
    var r = f(node, scope, c, name);
    if (out != null) r.propagate(out);
    return r;
  };
}

typedef FillExpr = Dynamic->Scope->Dynamic->AVal->String->AVal;

function fill(f:FillExpr):FillExpr {
  return function(node:Dynamic, scope:Scope, c:Dynamic, out:AVal, name:String):AVal {
    if (out == null) out = new AVal();
    f(node, scope, c, out, name);
    return out;
  };
}

var inferExprVisitor:Map<String, InferExpr> = new Map<String, InferExpr>({
  ArrayExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic):AVal {
    var eltval = new AVal();
    for (var i = 0; i < node.elements.length; ++i) {
      var elt = node.elements[i];
      if (elt != null) infer(elt, scope, c, eltval);
    }
    return new Arr(eltval);
  }),
  ObjectExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic, name:String):AVal {
    var obj = node.objType = new Obj(true, name);
    obj.originNode = node;

    for (var i = 0; i < node.properties.length; ++i) {
      var prop = node.properties[i];
      var key = prop.key;
      var name:String;
      if (prop.value.name == "✖") continue;

      if (key.type == "Identifier") {
        name = key.name;
      } else if (typeof key.value == "string") {
        name = key.value;
      }
      if (name == null || prop.kind == "set") {
        infer(prop.value, scope, c, ANull);
        continue;
      }

      var val = obj.defProp(name, key);
      var out = val;
      val.initializer = true;
      if (prop.kind == "get") {
        out = new IsCallee(obj, [], null, val);
      }
      infer(prop.value, scope, c, out, name);
    }
    return obj;
  }),
  FunctionExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic, name:String):AVal {
    var inner = node.body.scope;
    var fn = inner.fnType;
    if (name != null && fn.name == null) fn.name = name;
    c(node.body, scope, "ScopeBody");
    maybeTagAsInstantiated(node, inner) || maybeTagAsGeneric(inner);
    if (node.id != null) {
      inner.getProp(node.id.name).addType(fn);
    }
    return fn;
  }),
  SequenceExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic):AVal {
    for (var i = 0, l = node.expressions.length - 1; i < l; ++i) {
      infer(node.expressions[i], scope, c, ANull);
    }
    return infer(node.expressions[l], scope, c);
  }),
  UnaryExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic):AVal {
    infer(node.argument, scope, c, ANull);
    return unopResultType(node.operator);
  }),
  UpdateExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic):AVal {
    infer(node.argument, scope, c, ANull);
    return cx.num;
  }),
  BinaryExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic):AVal {
    if (node.operator == "+") {
      var lhs = infer(node.left, scope, c);
      var rhs = infer(node.right, scope, c);
      if (lhs.hasType(cx.str) || rhs.hasType(cx.str)) return cx.str;
      if (lhs.hasType(cx.num) && rhs.hasType(cx.num)) return cx.num;
      var result = new AVal();
      lhs.propagate(new IsAdded(rhs, result));
      rhs.propagate(new IsAdded(lhs, result));
      return result;
    } else {
      infer(node.left, scope, c, ANull);
      infer(node.right, scope, c, ANull);
      return binopIsBoolean(node.operator) ? cx.bool : cx.num;
    }
  }),
  AssignmentExpression: ret(function(node:Dynamic, scope:Scope, c:Dynamic):AVal {
    var rhs:Type, name:String, pName:String;
    if (node.left.type == "MemberExpression") {
      pName = propName(node.left, scope, c);
      if (node.left.object.type == "Identifier") {
        name = node.left.object.name + "." + pName;
      }
    } else {
      name = node.left.name;
    }

    if (node.operator != "=" && node.operator != "+=") {
      infer(node.right, scope, c, ANull);
      rhs = cx.num;
    } else {
      rhs = infer(node.right, scope, c, null, name);
    }

    if (node.left.type == "MemberExpression") {
      var obj = infer(node.left.object, scope, c);
      if (pName == "prototype") {
        maybeInstantiate(scope, 20);
      }
      if (pName == "<i>") {
        // This is a hack to recognize for/in loops that copy
        // properties, and do the copying ourselves, insofar as we
        // manage, because such loops tend to be relevant for type
        // information.
        var v = node.left.property.name;
        var local = scope.props[v];
        var over = local != null ? local.iteratesOver : null;
        if (over != null) {
          maybeInstantiate(scope, 20);
          var fromRight = node.right.type == "MemberExpression" && node.right.computed && node.right.property.name == v;
          over.forAllProps(function(prop:String, val:AVal, local:Bool) {
            if (local && prop != "prototype" && prop != "<i>") {
              obj.propagate(new PropHasSubset(prop, fromRight ? val : ANull));
            }
          });
          return rhs;
        }
      }
      obj.propagate(new PropHasSubset(pName, rhs, node.left.property));
    } else { // Identifier
      rhs.propagate(scope.defVar(node.left.name, node.left));
    }
    return rhs;
  }),
  LogicalExpression: fill(function(node:Dynamic, scope:Scope, c:Dynamic, out:AVal):Void {
    infer(node.left, scope, c, out);
    infer(node.right, scope, c, out);
  }),
  ConditionalExpression: fill(function(node:Dynamic, scope:Scope, c:Dynamic, out:AVal):Void {
    infer(node.test, scope, c, ANull);
    infer(node.consequent, scope, c, out);
    infer(node.alternate, scope, c, out);
  }),
  NewExpression: fill(function(node:Dynamic, scope:Scope, c:Dynamic, out:AVal, name:String):Void {
    if (node.callee.type == "Identifier" && node.callee.name in scope.props) {
      maybeInstantiate(scope, 20);
    }

    var args = new Array<AVal>();
    for (var i = 0; i < node.arguments.length; ++i) {
      args.push(infer(node.arguments[i], scope, c));
    }
    var callee = infer(node.callee, scope, c);
    var self = new AVal();
    callee.propagate(new IsCtor(self, name != null && /\.prototype$/.test(name)));
    self.propagate(out, WG_NEW_INSTANCE);
    callee.propagate(new IsCallee(self, args, node.arguments, new IfObj(out)));
  }),
  CallExpression: fill(function(node:Dynamic, scope:Scope, c:Dynamic, out:AVal):Void {
    var args = new Array<AVal>();
    for (var i = 0; i < node.arguments.length; ++i) {
      args.push(infer(node.arguments[i], scope, c));
    }
    if (node.callee.type == "MemberExpression") {
      var self = infer(node.callee.object, scope, c);
      var pName = propName(node.callee, scope, c);
      if ((pName == "call" || pName == "apply") && scope.fnType != null && scope.fnType.args.indexOf(self) > -1) {
        maybeInstantiate(scope, 30);
      }
      self.propagate(new HasMethodCall(pName, args, node.arguments, out));
    } else {
      var callee = infer(node.callee, scope, c);
      if (scope.fnType != null && scope.fnType.args.indexOf(callee) > -1) {
        maybeInstantiate(scope, 30);
      }
      var knownFn = callee.getFunctionType();
      if (knownFn != null && knownFn.instantiateScore != null && scope.fnType != null) {
        maybeInstantiate(scope, knownFn.instantiateScore / 5);
      }
      callee.propagate(new IsCallee(cx.topScope, args, node.arguments, out));
    }
  }),
  MemberExpression: fill(function(node:Dynamic, scope:Scope, c:Dynamic, out:AVal):Void {
    var name = propName(node, scope);
    var obj = infer(node.object, scope, c);
    var prop = obj.getProp(name);
    if (name == "<i>") {
      var propType = infer(node.property, scope, c);
      if (!propType.hasType(cx.num)) {
        return prop.propagate(out, WG_MULTI_MEMBER);
      }
    }
    prop.propagate(out);
  }),
  Identifier: ret(function(node:Dynamic, scope:Scope):AVal {
    if (node.name == "arguments" && scope.fnType != null && !(node.name in scope.props)) {
      scope.defProp(node.name, scope.fnType.originNode)
        .addType(new Arr(scope.fnType.arguments = new AVal()));
    }
    return scope.getProp(node.name);
  }),
  ThisExpression: ret(function(_node:Dynamic, scope:Scope):AVal {
    return scope.fnType != null ? scope.fnType.self : cx.topScope;
  }),
  Literal: ret(function(node:Dynamic):AVal {
    return literalType(node);
  })
});

function infer(node:Dynamic, scope:Scope, c:Dynamic, out:AVal = null, name:String = null):AVal {
  return inferExprVisitor[node.type](node, scope, c, out, name);
}

var inferWrapper = walk.make({
  Expression: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    infer(node, scope, c, ANull);
  },

  FunctionDeclaration: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    var inner = node.body.scope;
    var fn = inner.fnType;
    c(node.body, scope, "ScopeBody");
    maybeTagAsInstantiated(node, inner) || maybeTagAsGeneric(inner);
    var prop = scope.getProp(node.id.name);
    prop.addType(fn);
  },

  VariableDeclaration: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    for (var i = 0; i < node.declarations.length; ++i) {
      var decl = node.declarations[i];
      var prop = scope.getProp(decl.id.name);
      if (decl.init != null) {
        infer(decl.init, scope, c, prop, decl.id.name);
      }
    }
  },

  ReturnStatement: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    if (node.argument == null) return;
    var output:AVal = ANull;
    if (scope.fnType != null) {
      if (scope.fnType.retval == ANull) scope.fnType.retval = new AVal();
      output = scope.fnType.retval;
    }
    infer(node.argument, scope, c, output);
  },

  ForInStatement: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    var source = infer(node.right, scope, c);
    if ((node.right.type == "Identifier" && node.right.name in scope.props) ||
        (node.right.type == "MemberExpression" && node.right.property.name == "prototype")) {
      maybeInstantiate(scope, 5);
      var varName:String;
      if (node.left.type == "Identifier") {
        varName = node.left.name;
      } else if (node.left.type == "VariableDeclaration") {
        varName = node.left.declarations[0].id.name;
      }
      if (varName != null && varName in scope.props) {
        scope.getProp(varName).iteratesOver = source;
      }
    }
    c(node.body, scope, "Statement");
  },

  ScopeBody: function(node:Dynamic, scope:Scope, c:Dynamic):Void {
    c(node, node.scope || scope);
  }
});

// PARSING

typedef ParsePass = Dynamic->Dynamic->Void;

function runPasses(passes:Array<Array<ParsePass>>, pass:String, ?ast:Dynamic, ?text:String):Void {
  var arr = passes != null ? passes[pass] : null;
  var args = [ast, text];
  if (arr != null) {
    for (var i = 0; i < arr.length; ++i) {
      arr[i].apply(null, args);
    }
  }
}

class Options {
  public var reuseInstances:Bool = false;

  public function new() { }
}

function parse(text:String, ?passes:Array<Array<ParsePass>>, ?options:Options):Dynamic {
  var ast:Dynamic;
  try {
    ast = acorn.parse(text, options);
  } catch(e) {
    ast = acorn_loose.parse_dammit(text, options);
  }
  runPasses(passes, "postParse", ast, text);
  return ast;
}

// ANALYSIS INTERFACE

function analyze(ast:Dynamic, name:String = null, scope:Scope = null, ?passes:Array<Array<ParsePass>>):Void {
  if (typeof ast == "string") ast = parse(ast);

  if (name == null) {
    name = "file#" + cx.origins.length;
  }
  addOrigin(cx.curOrigin = name);

  if (scope == null) scope = cx.topScope;
  walk.recursive(ast, scope, null, scopeGatherer);
  runPasses(passes, "preInfer", ast, scope);
  walk.recursive(ast, scope, null, inferWrapper);
  runPasses(passes, "postInfer", ast, scope);

  cx.curOrigin = null;
}

// PURGING

function purge(origins:Array<String>, start:Int, end:Int):Void {
  var test = makePredicate(origins, start, end);
  ++cx.purgeGen;
  cx.topScope.purge(test);
  for (var prop in cx.props) {
    var list = cx.props[prop];
    for (var i = 0; i < list.length; ++i) {
      var obj = list[i];
      var av = obj.props[prop];
      if (av == null || test(av, av.originNode)) {
        list.splice(i--, 1);
      }
    }
    if (list.length == 0) {
      delete cx.props[prop];
    }
  }
}

function makePredicate(origins:Array<String>, start:Int, end:Int):Dynamic {
  var arr = origins is Array<String>;
  if (arr && origins.length == 1) {
    origins = origins[0];
    arr = false;
  }
  if (arr) {
    if (end == null) {
      return function(n:AVal):Bool {
        return origins.indexOf(n.origin) > -1;
      };
    } else {
      return function(n:AVal, pos:Dynamic):Bool {
        return pos != null && pos.start >= start && pos.end <= end && origins.indexOf(n.origin) > -1;
      };
    }
  } else {
    if (end == null) {
      return function(n:AVal):Bool {
        return n.origin == origins;
      };
    } else {
      return function(n:AVal, pos:Dynamic):Bool {
        return pos != null && pos.start >= start && pos.end <= end && n.origin == origins;
      };
    }
  }
}

// EXPRESSION TYPE
// EXPRESSION TYPE DETERMINATION

function findByPropertyName(name:String):AVal {
  guessing = true;
  var found = objsWithProp(name);
  if (found != null) {
    for (var i = 0; i < found.length; ++i) {
      var val = found[i].getProp(name);
      if (!val.isEmpty()) return val;
    }
  }
  return ANull;
}

var typeFinder:Map<String, Dynamic->Scope->AVal> = new Map<String, Dynamic->Scope->AVal>({
  ArrayExpression: function(node:Dynamic, scope:Scope):AVal {
    var eltval = new AVal();
    for (var i = 0; i < node.elements.length; ++i) {
      var elt = node.elements[i];
      if (elt != null) findType(elt, scope).propagate(eltval);
    }
    return new Arr(eltval);
  },
  ObjectExpression: function(node:Dynamic):AVal {
    return node.objType;
  },
  FunctionExpression: function(node:Dynamic):AVal {
    return node.body.scope.fnType;
  },
  SequenceExpression: function(node:Dynamic, scope:Scope):AVal {
    return findType(node.expressions[node.expressions.length - 1], scope);
  },
  UnaryExpression: function(node:Dynamic):AVal {
    return unopResultType(node.operator);
  },
  UpdateExpression: function():AVal {
    return cx.num;
  },
  BinaryExpression: function(node:Dynamic, scope:Scope):AVal {
    if (binopIsBoolean(node.operator)) return cx.bool;
    if (node.operator == "+") {
      var lhs = findType(node.left, scope);
      var rhs = findType(node.right, scope);
      if (lhs.hasType(cx.str) || rhs.hasType(cx.str)) return cx.str;
    }
    return cx.num;
  },
  AssignmentExpression: function(node:Dynamic, scope:Scope):AVal {
    return findType(node.right, scope);
  },
  LogicalExpression: function(node:Dynamic, scope:Scope):AVal {
    var lhs = findType(node.left, scope);
    return lhs.isEmpty() ? findType(node.right, scope) : lhs;
  },
  ConditionalExpression: function(node:Dynamic, scope:Scope):AVal {
    var lhs = findType(node.consequent, scope);
    return lhs.isEmpty() ? findType(node.alternate, scope) : lhs;
  },
  NewExpression: function(node:Dynamic, scope:Scope):AVal {
    var f = findType(node.callee, scope).getFunctionType();
    var proto = f != null ? f.getProp("prototype").getObjType() : null;
    if (proto == null) return ANull;
    return getInstance(proto, f);
  },
  CallExpression: function(node:Dynamic, scope:Scope):AVal {
    var f = findType(node.callee, scope).getFunctionType();
    if (f == null) return ANull;
    if (f.computeRet != null) {
      var args = new Array<AVal>();
      for (var i = 0; i < node.arguments.length; ++i) {
        args.push(findType(node.arguments[i], scope));
      }
      var self:AVal = ANull;
      if (node.callee.type == "MemberExpression") {
        self = findType(node.callee.object, scope);
      }
      return f.computeRet(self, args, node.arguments);
    } else {
      return f.retval;
    }
  },
  MemberExpression: function(node:Dynamic, scope:Scope):AVal {
    var propN = propName(node, scope);
    var obj = findType(node.object, scope).getType();
    if (obj != null) return obj.getProp(propN);
    if (propN == "<i>") return ANull;
    return findByPropertyName(propN);
  },
  Identifier: function(node:Dynamic, scope:Scope):AVal {
    return scope.hasProp(node.name) || ANull;
  },
  ThisExpression: function(_node:Dynamic, scope:Scope):AVal {
    return scope.fnType != null ? scope.fnType.self : cx.topScope;
  },
  Literal: function(node:Dynamic):AVal {
    return literalType(node);
  }
});

function findType(node:Dynamic, scope:Scope):AVal {
  return typeFinder[node.type](node, scope);
}

// Finding the expected type of something, from context

typedef ParentNode = Dynamic->Dynamic->Dynamic;

var findTypeFromContext:Map<String, ParentNode->Dynamic->Dynamic->Dynamic> = new Map<String, ParentNode->Dynamic->Dynamic->Dynamic>({
  ArrayExpression: function(parent:Dynamic, _, get:Dynamic->Bool->Dynamic):Dynamic {
    return get(parent, true).getProp("<i>");
  },
  ObjectExpression: function(parent:Dynamic, node:Dynamic, get:Dynamic->Bool->Dynamic):Dynamic {
    for (var i = 0; i < parent.properties.length; ++i) {
      var prop = parent.properties[i];
      if (prop.value == node) {
        return get(parent, true).getProp(prop.key.name);
      }
    }
    return null;
  },
  UnaryExpression: function(parent:Dynamic):Dynamic {
    return unopResultType(parent.operator);
  },
  UpdateExpression: function():Dynamic {
    return cx.num;
  },
  BinaryExpression: function(parent:Dynamic):Dynamic {
    return binopIsBoolean(parent.operator) ? cx.bool : cx.num;
  },
  AssignmentExpression: function(parent:Dynamic, _, get:Dynamic->Bool->Dynamic):Dynamic {
    return get(parent.left);
  },
  LogicalExpression: function(parent:Dynamic, _, get:Dynamic->Bool->Dynamic):Dynamic {
    return get(parent, true);
  },
  ConditionalExpression: function(parent:Dynamic, node:Dynamic, get:Dynamic->Bool->Dynamic):Dynamic {
    if (parent.consequent == node || parent.alternate == node) return get(parent, true);
    return null;
  },
  NewExpression: function(parent:Dynamic, node:Dynamic, get:Dynamic->Bool->Dynamic):Dynamic {
    return this.CallExpression(parent, node, get);
  },
  CallExpression: function(parent:Dynamic, node:Dynamic, get:Dynamic->Bool->Dynamic):Dynamic {
    for (var i = 0; i < parent.arguments.length; i++) {
      var arg = parent.arguments[i];
      if (arg == node) {
        var calleeType = get(parent.callee).getFunctionType();
        if (calleeType is Fn) {
          return calleeType.args[i];
        }
        break;
      }
    }
    return null;
  },
  ReturnStatement: function(_parent:Dynamic, node:Dynamic, get:Dynamic->Bool->Dynamic):Dynamic {
    var fnNode = walk.findNodeAround(node.sourceFile.ast, node.start, "Function");
    if (fnNode != null) {
      var fnType = fnNode.node.type == "FunctionExpression" ? get(fnNode.node, true).getFunctionType() : fnNode.node.body.scope.fnType;
      if (fnType != null) return fnType.retval.getType();
    }
    return null;
  },
  VariableDeclaration: function(parent:Dynamic, node:Dynamic, get:Dynamic->Bool->Dynamic):Dynamic {
    for (var i = 0; i < parent.declarations.length; i++) {
      var decl = parent.declarations[i];
      if (decl.init == node) return get(decl.id);
    }
    return null;
  }
});

var parentNode:ParentNode = function(child:Dynamic, ast:Dynamic):Dynamic {
  var stack = new Array<Dynamic>();
  function c(node:Dynamic, st:Dynamic, override:String = null):Void {
    if (node.start <= child.start && node.end >= child.end) {
      var top = stack[stack.length - 1];
      if (node == child) throw {found: top};
      if (top != node) stack.push(node);
      walk.base[override != null ? override : node.type](node, st, c);
      if (top != node) stack.pop();
    }
  }
  try {
    c(ast, null);
  } catch(e) {
    if (e.found != null) return e.found;
    throw e;
  }
  return null;
};

function typeFromContext(ast:Dynamic, found:Dynamic):AVal {
  var parent = parentNode(found.node, ast);
  var type:AVal = null;
  if (findTypeFromContext.hasOwnProperty(parent.type)) {
    type = findTypeFromContext[parent.type](parent, found.node, function(node:Dynamic, fromContext:Bool):AVal {
      var obj = {node: node, state: found.state};
      var tp = fromContext ? typeFromContext(ast, obj) : expressionType(obj);
      return tp || ANull;
    });
  }
  return type || expressionType(found);
}

// Flag used to indicate that some wild guessing was used to produce
// a type or set of completions.
var guessing:Bool = false;

function resetGuessing(val:Bool):Void {
  guessing = val;
}

function didGuess():Bool {
  return guessing;
}

function forAllPropertiesOf(type:Type, f:Dynamic):Void {
  type.gatherProperties(f, 0);
}

var refFindWalker = walk.make({}, searchVisitor);

function findRefs(ast:Dynamic, baseScope:Scope, name:String, refScope:Scope, f:Dynamic):Void {
  refFindWalker.Identifier = function(node:Dynamic, scope:Scope):Void {
    if (node.name != name) return;
    for (var s = scope; s != null; s = s.prev) {
      if (s == refScope) f(node, scope);
      if (name in s.props) return;
    }
  };
  walk.recursive(ast, baseScope, null, refFindWalker);
}

var simpleWalker = walk.make({
  Function: function(node:Dynamic, _st:Dynamic, c:Dynamic):Void {
    c(node.body, node.body.scope, "ScopeBody");
  }
});

function findPropRefs(ast:Dynamic, scope:Scope, objType:Obj, propName:String, f:Dynamic):Void {
  walk.simple(ast, {
    MemberExpression: function(node:Dynamic, scope:Scope):Void {
      if (node.computed || node.property.name != propName) return;
      if (findType(node.object, scope).getType() == objType) f(node.property);
    },
    ObjectExpression: function(node:Dynamic, scope:Scope):Void {
      if (findType(node, scope).getType() != objType) return;
      for (var i = 0; i < node.properties.length; ++i) {
        if (node.properties[i].key.name == propName) f(node.properties[i].key);
      }
    }
  }, simpleWalker, scope);
}

// LOCAL-VARIABLE QUERIES

var scopeAt:Dynamic->Int->Scope->Scope = function(ast:Dynamic, pos:Int, defaultScope:Scope = null):Scope {
  var found = walk.findNodeAround(ast, pos, function(tp:String, node:Dynamic):Bool {
    return tp == "ScopeBody" && node.scope != null;
  });
  if (found != null) return found.node.scope;
  else return defaultScope || cx.topScope;
};

function forAllLocalsAt(ast:Dynamic, pos:Int, defaultScope:Scope = null, f:Dynamic):Void {
  var scope = scopeAt(ast, pos, defaultScope);
  scope.gatherProperties(f, 0);
}

// INIT DEF MODULE

// Delayed initialization because of cyclic dependencies.
var def:Dynamic = exports.def = def.init({}, exports);

// CONSTANTS

var WG_DEFAULT:Int = 100;
var WG_NEW_INSTANCE:Int = 90;
var WG_MADEUP_PROTO:Int = 10;
var WG_MULTI_MEMBER:Int = 5;
var WG_CATCH_ERROR:Int = 5;
var WG_GLOBAL_THIS:Int = 90;
var WG_SPECULATIVE_THIS:Int = 2;

function getInstance(obj:Obj, ctor:Fn = null):Obj {
  if (ctor == false) return new Obj(obj);

  if (ctor == null) ctor = obj.hasCtor;
  if (obj.instances == null) obj.instances = [];
  for (var i = 0; i < obj.instances.length; ++i) {
    var cur = obj.instances[i];
    if (cur.ctor == ctor) return cur.instance;
  }
  var instance = new Obj(obj, ctor != null ? ctor.name : null);
  instance.origin = obj.origin;
  obj.instances.push({ctor: ctor, instance: instance});
  return instance;
}

function similarAVal(a:AVal, b:AVal, depth:Int):Bool {
  var typeA = a.getType(false);
  var typeB = b.getType(false);
  if (typeA == null || typeB == null) return true;
  return similarType(typeA, typeB, depth);
}

function similarType(a:Type, b:Type, depth:Int):Bool {
  if (a == null || depth >= 5) return b != null;
  if (a == b) return true;
  if (b == null) return false;
  if (a.constructor != b.constructor) return false;
  if (a is Arr) {
    var innerA = a.getProp("<i>").getType(false);
    if (innerA == null) return b != null;
    var innerB = b.getProp("<i>").getType(false);
    if (innerB == null || similarType(innerA, innerB, depth + 1)) return b != null;
  } else if (a is Obj) {
    var propsA = 0, propsB = 0, same = 0;
    for (var prop in a.props) {
      propsA++;
      if (prop in b.props && similarAVal(a.props[prop], b.props[prop], depth + 1)) {
        same++;
      }
    }
    for (var prop in b.props) propsB++;
    if (propsA > 0 && propsB > 0 && same < Math.max(propsA, propsB) / 2) return false;
    return propsA > propsB ? a != null : b != null;
  } else if (a is Fn) {
    if (a.args.length != b.args.length ||
        !a.args.every(function(tp:Type, i:Int):Bool { return similarAVal(tp, b.args[i], depth + 1); }) ||
        !similarAVal(a.retval, b.retval, depth + 1) || !similarAVal(a.self, b.self, depth + 1)) {
      return false;
    }
    return true;
  } else {
    return false;
  }
}

function simplifyTypes(types:Array<Type>):Array<Type> {
  var found = new Array<Type>();
  outer: for (var i = 0; i < types.length; ++i) {
    var tp = types[i];
    for (var j = 0; j < found.length; j++) {
      var similar = similarType(tp, found[j], 0);
      if (similar) {
        found[j] = similar;
        continue outer;
      }
    }
    found.push(tp);
  }
  return found;
}

function canonicalType(types:Array<Type>):Type {
  var arrays = 0, fns = 0, objs = 0, prim:Prim = null;
  for (var i = 0; i < types.length; ++i) {
    var tp = types[i];
    if (tp is Arr) ++arrays;
    else if (tp is Fn) ++fns;
    else if (tp is Obj) ++objs;
    else if (tp is Prim) {
      if (prim != null && tp.name != prim.name) return null;
      prim = tp;
    }
  }
  var kinds = (arrays > 0 ? 1 : 0) + (fns > 0 ? 1 : 0) + (objs > 0 ? 1 : 0) + (prim != null ? 1 : 0);
  if (kinds > 1) return null;
  if (prim != null) return prim;

  var maxScore = 0, maxTp:Type = null;
  for (var i = 0; i < types.length; ++i) {
    var tp = types[i];
    var score = 0;
    if (arrays > 0) {
      score = tp.getProp("<i>").isEmpty() ? 1 : 2;
    } else if (fns > 0) {
      score = 1;
      for (var j = 0; j < tp.args.length; ++j) {
        if (!tp.args[j].isEmpty()) ++score;
      }
      if (!tp.retval.isEmpty()) ++score;
    } else if (objs > 0) {
      score = tp.name != null ? 100 : 2;
    }
    if (score >= maxScore) {
      maxScore = score;
      maxTp = tp;
    }
  }
  return maxTp;
}

function expressionType(found:Dynamic):AVal {
  return findType(found.node, found.state);
}

var searchVisitor = exports.searchVisitor = walk.make({
  Function: function(node:Dynamic, _st:Dynamic, c:Dynamic):Void {
    var scope = node.body.scope;
    if (node.id != null) c(node.id, scope);
    for (var i = 0; i < node.params.length; ++i) {
      c(node.params[i], scope);
    }
    c(node.body, scope, "ScopeBody");
  },
  TryStatement: function(node:Dynamic, st:Dynamic, c:Dynamic):Void {
    if (node.handler != null) {
      c(node.handler.param, st);
    }
    walk.base.TryStatement(node, st, c);
  },
  VariableDeclaration: function(node:Dynamic, st:Dynamic, c:Dynamic):Void {
    for (var i = 0; i < node.declarations.length; ++i) {
      var decl = node.declarations[i];
      c(decl.id, st);
      if (decl.init != null) {
        c(decl.init, st, "Expression");
      }
    }
  }
});
exports.fullVisitor = walk.make({
  MemberExpression: function(node:Dynamic, st:Dynamic, c:Dynamic):Void {
    c(node.object, st, "Expression");
    c(node.property, st, node.computed ? "Expression" : null);
  },
  ObjectExpression: function(node:Dynamic, st:Dynamic, c:Dynamic):Void {
    for (var i = 0; i < node.properties.length; ++i) {
      c(node.properties[i].value, st, "Expression");
      c(node.properties[i].key, st);
    }
  }
}, searchVisitor);

function findExpressionAt(ast:Dynamic, start:Int, end:Int, defaultScope:Scope = null, filter:Dynamic = null):{node:Dynamic, state:Scope} {
  var test = filter != null ? filter : function(_t:String, node:Dynamic):Bool {
    if (node.type == "Identifier" && node.name == "✖") return false;
    return typeFinder.hasOwnProperty(node.type);
  };
  return walk.findNodeAt(ast, start, end, test, searchVisitor, defaultScope || cx.topScope);
}

function findExpressionAround(ast:Dynamic, start:Int, end:Int, defaultScope:Scope = null, filter:Dynamic = null):{node:Dynamic, state:Scope} {
  var test = filter != null ? filter : function(_t:String, node:Dynamic):Bool {
    if (start != null && node.start > start) return false;
    if (node.type == "Identifier" && node.name == "✖") return false;
    return typeFinder.hasOwnProperty(node.type);
  };
  return walk.findNodeAround(ast, end, test, searchVisitor, defaultScope || cx.topScope);
}

function toString(type:Type, maxDepth:Null<Int> = null, parent:Type = null):String {
  if (type == null || type == parent || (maxDepth != null && maxDepth < -3)) return "?";
  return type.toString(maxDepth, parent);
}