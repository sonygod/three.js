import js.QUnit;
import three.src.renderers.webgl.WebGLRenderLists;
import three.src.renderers.webgl.WebGLRenderList;
import three.src.scenes.Scene;

class WebGLRenderListsTests {
    public function new() {
        QUnit.module("Renderers", () -> {
            QUnit.module("WebGL", () -> {
                QUnit.module("WebGLRenderLists", () -> {
                    QUnit.test("get", (assert: QUnit.Assert) -> {
                        var renderLists = new WebGLRenderLists();
                        var sceneA = new Scene();
                        var sceneB = new Scene();

                        var listA = renderLists.get(sceneA);
                        var listB = renderLists.get(sceneB);

                        assert.propEqual(listA, new WebGLRenderList(), "listA is type of WebGLRenderList.");
                        assert.propEqual(listB, new WebGLRenderList(), "listB is type of WebGLRenderList.");
                        assert.ok(listA != listB, "Render lists are different.");
                    });
                });

                QUnit.module("WebGLRenderList", () -> {
                    QUnit.test("init", (assert: QUnit.Assert) -> {
                        var list = new WebGLRenderList();

                        assert.ok(list.transparent.length == 0, "Transparent list defaults to length 0.");
                        assert.ok(list.opaque.length == 0, "Opaque list defaults to length 0.");

                        list.push({}, {}, {transparent: true}, 0, 0.5, {});
                        list.push({}, {}, {transparent: false}, 0, 0, {});

                        assert.ok(list.transparent.length == 1, "Transparent list is length 1 after adding transparent item.");
                        assert.ok(list.opaque.length == 1, "Opaque list list is length 1 after adding opaque item.");

                        list.init();

                        assert.ok(list.transparent.length == 0, "Transparent list is length 0 after calling init.");
                        assert.ok(list.opaque.length == 0, "Opaque list list is length 0 after calling init.");
                    });

                    QUnit.test("push", (assert: QUnit.Assert) -> {
                        var list = new WebGLRenderList();
                        var objA = {id: "A", renderOrder: 0};
                        var matA = {transparent: true};
                        var geoA = {};

                        var objB = {id: "B", renderOrder: 0};
                        var matB = {transparent: true};
                        var geoB = {};

                        var objC = {id: "C", renderOrder: 0};
                        var matC = {transparent: false};
                        var geoC = {};

                        var objD = {id: "D", renderOrder: 0};
                        var matD = {transparent: false};
                        var geoD = {};

                        // ... continue with the rest of your tests ...
                    });

                    // ... continue with the rest of your modules ...
                });
            });
        });
    }
}