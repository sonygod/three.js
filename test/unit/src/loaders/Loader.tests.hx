package three.test.unit.src.loaders;

import three.loaders.Loader;
import three.loaders.LoadingManager;

class LoaderTests {
    public function new() {}

    public static function main() {
        suite("Loaders", () -> {
            suite("Loader", () -> {
                test("Instancing", () -> {
                    var object = new Loader();
                    assert(object != null, "Can instantiate a Loader.");
                });

                test("manager", () -> {
                    // uses default LoadingManager if not supplied in constructor
                    var object:LoadingManager = new Loader().manager;
                    assertTrue(object instanceof LoadingManager, "Loader defines a default manager if not supplied in constructor.");
                });

                test("crossOrigin", () -> {
                    var actual = new Loader().crossOrigin;
                    var expected = "anonymous";
                    assertEquals(actual, expected, "Loader defines crossOrigin.");
                });

                test("withCredentials", () -> {
                    var actual = new Loader().withCredentials;
                    var expected = false;
                    assertEquals(actual, expected, "Loader defines withCredentials.");
                });

                test("path", () -> {
                    var actual = new Loader().path;
                    var expected = "";
                    assertEquals(actual, expected, "Loader defines path.");
                });

                test("resourcePath", () -> {
                    var actual = new Loader().resourcePath;
                    var expected = "";
                    assertEquals(actual, expected, "Loader defines resourcePath.");
                });

                test("requestHeader", () -> {
                    var actual = new Loader().requestHeader;
                    var expected = {};
                    assertEquals(actual, expected, "Loader defines requestHeader.");
                });

                // PUBLIC
                todo("load", () -> {
                    assert(false, "everything's gonna be alright");
                });

                todo("loadAsync", () -> {
                    assert(false, "everything's gonna be alright");
                });

                todo("parse", () -> {
                    assert(false, "everything's gonna be alright");
                });

                todo("setCrossOrigin", () -> {
                    assert(false, "everything's gonna be alright");
                });

                todo("setWithCredentials", () -> {
                    assert(false, "everything's gonna be alright");
                });

                todo("setPath", () -> {
                    assert(false, "everything's gonna be alright");
                });

                todo("setResourcePath", () -> {
                    assert(false, "everything's gonna be alright");
                });

                todo("setRequestHeader", () -> {
                    assert(false, "everything's gonna be alright");
                });
            });
        });
    }
}