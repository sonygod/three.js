import js.QUnit.*;
import UniformsGroup from "../../../../src/core/UniformsGroup.hx";
import EventDispatcher from "../../../../src/core/EventDispatcher.hx";

@:autoBuild(false)
class TestUniformsGroup {
    static testExtending() {
        var object = new UniformsGroup();
        ok(Std.is(object, EventDispatcher), "UniformsGroup extends from EventDispatcher");
    }

    static testInstancing() {
        var object = new UniformsGroup();
        ok(object != null, "Can instantiate a UniformsGroup.");
    }

    static testIsUniformsGroup() {
        var object = new UniformsGroup();
        ok(object.isUniformsGroup, "UniformsGroup.isUniformsGroup should be true");
    }

    static testDispose() {
        var object = new UniformsGroup();
        object.dispose();
    }

    public static function main() {
        module("Core", {
            setup: function() {}, teardown: function() {}
        });

        module("UniformsGroup", {
            setup: function() {}, teardown: function() {}
        });

        test("Extending", TestUniformsGroup.testExtending);
        test("Instancing", TestUniformsGroup.testInstancing);
        test("isUniformsGroup", TestUniformsGroup.testIsUniformsGroup);
        test("dispose", TestUniformsGroup.testDispose);
    }
}

TestUniformsGroup.main();