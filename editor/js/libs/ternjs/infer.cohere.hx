// Main type inference engine

// Walks an AST, building up a graph of abstract values and constraints
// that cause types to flow from one node to another. Also defines a
// number of utilities for accessing ASTs and scopes.

// Analysis is done in a context, which is tracked by the dynamically
// bound cx variable. Use withContext to set the current context.

// For memory-saving reasons, individual types export an interface
// similar to abstract values (which can hold multiple types), and can
// thus be used in place abstract values that only ever contain a
// single type.

(function (root, mod) {
    if (typeof exports == "object" && typeof module == "object") // CommonJS
        return mod(exports, require("acorn"), require("acorn/dist/acorn_loose"), require("acorn/dist/walk"),
            require("./def"), require("./signal"));
    if (typeof define == "function" && define.amd) // AMD
        return define(["exports", "acorn/dist/acorn", "acorn/dist/acorn_loose", "acorn/dist/walk", "./def", "./signal"], mod);
    mod(root.tern || (root.tern = {}), acorn, acorn, acorn.walk, tern.def, tern.signal); // Plain browser env
})(this, function (exports, acorn, acorn_loose, walk, def, signal) {
    "use strict";

    var toString = exports.toString = function (type, maxDepth, parent) {
        if (!type || type == parent || maxDepth && maxDepth < -3) return "?";
        return type.toString(maxDepth, parent);
    };

    // A variant of AVal used for unknown, dead-end values. Also serves
    // as prototype for AVals, Types, and Constraints because it
    // implements 'empty' versions of all the methods that the code
    // expects.
    var ANull = exports.ANull = signal.mixin({
        addType: function () { },
        propagate: function () { },
        getProp: function () { return ANull; },
        forAllProps: function () { },
        hasType: function () { return false; },
        isEmpty: function () { return true; },
        getFunctionType: function () { },
        getObjType: function () { },
        getType: function () { },
        gatherProperties: function () { },
        propagatesTo: function () { },
        typeHint: function () { },
        propHint: function () { },
        toString: function () { return "?"; }
    });

    function extend(proto, props) {
        var obj = Object.create(proto);
        if (props) for (var prop in props) obj[prop] = props[prop];
        return obj;
    }

    // ABSTRACT VALUES

    var WG_DEFAULT = 100, WG_NEW_INSTANCE = 90, WG_MADEUP_PROTO = 10, WG_MULTI_MEMBER = 5,
        WG_CATCH_ERROR = 5, WG_GLOBAL_THIS = 90, WG_SPECULATIVE_THIS = 2;

    var AVal = exports.AVal = function () {
        this.types = [];
        this.forward = null;
        this.maxWeight = 0;
    };
    AVal.prototype = extend(ANull, {
        addType: function (type, weight) {
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
            if (forward) withWorklist(function (add) {
                for (var i = 0; i < forward.length; ++i) add(type, forward[i], weight);
            });
        },

        propagate: function (target, weight) {
            if (target == ANull || (target instanceof Type && this.forward && this.forward.length > 2)) return;
            if (weight && weight != WG_DEFAULT) target = new Muffle(target, weight);
            (this.forward || (this.forward = [])).push(target);
            var types = this.types;
            if (types.length) withWorklist(function (add) {
                for (var i = 0; i < types.length; ++i) add(types[i], target, weight);
            });
        },

        getProp: function (prop) {
            if (prop == "__proto__" || prop == "✖") return ANull;
            var found = (this.props || (this.props = Object.create(null)))[prop];
            if (!found) {
                found = this.props[prop] = new AVal;
                this.propagate(new PropIsSubset(prop, found));
            }
            return found;
        },

        forAllProps: function (c) {
            this.propagate(new ForAllProps(c));
        },

        hasType: function (type) {
            return this.types.indexOf(type) > -1;
        },
        isEmpty: function () { return this.types.length === 0; },
        getFunctionType: function () {
            for (var i = this.types.length - 1; i >= 0; --i)
                if (this.types[i] instanceof Fn) return this.types[i];
        },
        getObjType: function () {
            var seen = null;
            for (var i = this.types.length - 1; i >= 0; --i) {
                var type = this.types[i];
                if (!(type instanceof Obj)) continue;
                if (type.name) return type;
                if (!seen) seen = type;
            }
            return seen;
        },

        getType: function (guess) {
            if (this.types.length === 0 && guess !== false) return this.makeupType();
            if (this.types.length == 1) return this.types[0];
            return canonicalType(this.types);
        },

        toString: function (maxDepth, parent) {
            if (this.types.length == 0) return toString(this.makeupType(), maxDepth, parent);
            if (this.types.length == 1) return toString(this.types[0], maxDepth, parent);
            var simplified = simplifyTypes(this.types);
            if (simplified.length > 2) return "?";
            return simplified.map(function (tp) { return toString(tp, maxDepth, parent); }).join("|");
        },

        computedPropType: function () {
            if (!this.propertyOf) return null;
            if (this.propertyOf.hasProp("<i>")) {
                var computedProp = this.propertyOf.getProp("<i>");
                if (computedProp == this) return null;
                return computedProp.getType();
            } else if (this.propertyOf.maybeProps && this.propertyOf.maybeProps["<i>"] == this) {
                for (var prop in this.propertyOf.props) {
                    var val = this.propertyOf.props[prop];
                    if (!val.isEmpty()) return val;
                }
                return null;
            }
        },

        makeupType: function () {
            var computed = this.computedPropType();
            if (computed) return computed;

            if (!this.forward) return null;
            for (var i = this.forward.length - 1; i >= 0; --i) {
                var hint = this.forward[i].typeHint();
                if (hint && !hint.isEmpty()) { guessing = true; return hint; }
            }

            var props = Object.create(null), foundProp = null;
            for (var i = 0; i < this.forward.length; ++i) {
                var prop = this.forward[i].propHint();
                if (prop && prop != "length" && prop != "<i>" && prop != "✖" && prop != cx.completingProperty) {
                    props[prop] = true;
                    foundProp = prop;
                }
            }
            if (!foundProp) return null;

            var objs = objsWithProp(foundProp);
            if (objs) {
                var matches = [];
                search: for (var i = 0; i < objs.length; ++i) {
                    var obj = objs[i];
                    for (var prop in props) if (!obj.hasProp(prop)) continue search;
                    if (obj.hasCtor) obj = getInstance(obj);
                    matches.push(obj);
                }
                var canon = canonicalType(matches);
                if (canon) { guessing = true; return canon; }
            }
        },

        typeHint: function () { return this.types.length ? this.getType() : null; },
        propagatesTo: function () { return this; },

        gatherProperties: function (f, depth) {
            for (var i = 0; i < this.types.length; ++i)
                this.types[i].gatherProperties(f, depth);
        },

        guessProperties: function (f) {
            if (this.forward) for (var i = 0; i < this.forward.length; ++i) {
                var prop = this.forward[i].propHint();
                if (prop) f(prop, null, 0);
            }
            var guessed = this.makeupType();
            if (guessed) guessed.gatherProperties(f);
        }
    });

    function similarAVal(a, b, depth) {
        var typeA = a.getType(false), typeB = b.getType(false);
        if (!typeA || !typeB) return true;
        return similarType(typeA, typeB, depth);
    }

    function similarType(a, b, depth) {
        if (!a || depth >= 5) return b;
        if (a == b) return a;
        if (!b) return a;
        if (a.constructor != b.constructor) return false;
        if (a.constructor == Arr) {
            var innerA = a.getProp("<i>").getType(false);
            if (!innerA) return b;
            var innerB = b.getProp("<i>").getType(false);
            if (!innerB || similarType(innerA, innerB, depth + 1)) return b;
        } else if (a.constructor == Obj) {
            var propsA = 0, propsB = 0, same = 0;
            for (var prop in a.props) {
                propsA++;
                if (prop in b.props && similarAVal(a.props[prop], b.props[prop], depth + 1))
                    same++;
            }
            for (var prop in b.props) propsB++;
            if (propsA && propsB && same < Math.max(propsA, propsB) / 2) return false;
            return propsA > propsB ? a : b;
        } else if (a.constructor == Fn) {
            if (a.args.length != b.args.length ||
                !a.args.every(function (tp, i) { return similarAVal(tp, b.args[i], depth + 1); }) ||
                !similarAVal(a.retval, b.retval, depth + 1) || !similarAVal(a.self, b.self, depth + 1))
                return false;
            return a;
        } else {
            return false;
        }
    }

    var simplifyTypes = exports.simplifyTypes = function (types) {
        var found = [];
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
    };

    function canonicalType(types) {
        var arrays = 0, fns = 0, objs = 0, prim = null;
        for (var i = 0; i < types.length; ++i) {
            var tp = types[i];
            if (tp instanceof Arr) ++arrays;
            else if (tp instanceof Fn) ++fns;
            else if (tp instanceof Obj) ++objs;
            else if (tp instanceof Prim) {
                if (prim && tp.name != prim.name) return null;
                prim = tp;
            }
        }
        var kinds = (arrays && 1) + (fns && 1) + (objs && 1) + (prim && 1);
        if (kinds > 1) return null;
        if (prim) return prim;

        var maxScore = 0, maxTp = null;
        for (var i = 0; i < types.length; ++i) {
            var tp = types[i], score = 0;
            if (arrays) {
                score = tp.getProp("<i>").isEmpty() ? 1 : 2;
            } else if (fns) {
                score = 1;
                for (var j = 0; j < tp.args.length; ++j) if (!tp.args[j].isEmpty()) ++score;
                if (!tp.retval.isEmpty()) ++score;
            } else if (objs) {
                score = tp.name ? 100 : 2;
            }
            if (score >= maxScore) { maxScore = score; maxTp = tp; }
        }
        return maxTp;
    }

    // PROPAGATION STRATEGIES

    function Constraint() { }
    Constraint.prototype = extend(ANull, {
        init: function () { this.origin = cx.curOrigin; }
    });

    var constraint = exports.constraint = function (props, methods) {
        var body = "this.init();";
        props = props ? props.split(", ") : [];
        for (var i = 0; i < props.length; ++i)
            body += "this." + props[i] + " = " + props[i] + ";";
        var ctor = Function.apply(null, props.concat([body]));
        ctor.prototype = Object.create(Constraint.prototype);
        for (var m in methods) if (methods.hasOwnProperty(m)) ctor.prototype[m] = methods[m];
        return ctor;
    };

    var PropIsSubset = constraint("prop, target", {
        addType: function (type, weight) {
            if (type.getProp)
                type.getProp(this.prop).propagate(this.target, weight);
        },
        propHint: function () { return this.prop; },
        propagatesTo: function () {
            if (this.prop == "<i>" || !/[^\w_]/.test(this.prop))
                return { target: this.target, pathExt: "." + this.prop };
        }
    });

    var PropHasSubset = exports.PropHasSubset = constraint("prop, type, originNode", {
        addType: function (type, weight) {
            if (!(type instanceof Obj)) return;
            var prop = type.defProp(this.prop, this.originNode);
            if (!prop.origin) prop.origin = this.origin;
            this.type.propagate(prop, weight);
        },
        propHint: function () { return this.prop; }
    });

    var ForAllProps = constraint("c", {
        addType: function (type) {
            if (!(type instanceof Obj)) return;
            type.forAllProps(this.c);
        }
    });

    function withDisabledComputing(fn, body) {
        cx.disabledComputing = { fn: fn, prev: cx.disabledComputing };
        try {
            return body();
        } finally {
            cx.disabledComputing = cx.disabledComputing.prev;
        }
    }
    var IsCallee = exports.IsCallee = constraint("self, args, argNodes, retval", {
        init: function () {
            Constraint.prototype.init.call(this);
            this.disabled = cx.disabledComputing;
        },
        addType: function (fn, weight) {
            if (!(fn instanceof Fn)) return;
            for (var i = 0; i < this.args.length; ++i) {
                if (i < fn.args.length) this.args[i].propagate(fn.args[i], weight);
                if (fn.arguments) this.args[i].propagate(fn.arguments, weight);
            }
            this.self.propagate(fn.self, this.self == cx.topScope ? WG_GLOBAL_THIS : weight);
            var compute = fn.computeRet;
            if (compute) for (var d = this.disabled; d; d = d.prev)
                if (d.fn == fn || fn.originNode && d.fn.originNode == fn.originNode) compute = null;
            if (compute)
                compute(this.self, this.args, this.argNodes).propagate(this.retval, weight);
            else
                fn.retval.propagate(this.retval, weight);
        },
        typeHint: function () {
            var names = [];
            for (var i = 0; i < this.args.length; ++i) names.push("?");
            return new Fn(null, this.self, this.args, names, ANull);
        },
        propagatesTo: function () {
            return { target: this.retval, pathExt: ".!ret" };
        }
    });

    var HasMethodCall = constraint("propName, args, argNodes, retval", {
        init: function () {
            Constraint