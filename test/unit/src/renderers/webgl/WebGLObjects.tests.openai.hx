package three.test.unit.src.renderers.webgl;

import utest.Assert;
import utest.Test;

class WebGLObjectsTest {

    public function new() {}

    public static function main() {
        Test.createSuite("Renderers", () -> {
            Test.createSuite("WebGL", () -> {
                Test.createSuite("WebGLObjects", () -> {

                    Test.todoTest("Instancing", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todoTest("update", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todoTest("clear", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                });
            });
        });
    }

}