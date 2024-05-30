import js.QUnit.*;
import js.Math.*;

class ColorTest {
    static function main() {
        module("Maths > Color", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });

        test("Instancing", function() {
            var c = new Color();
            trace(c.r, c.g, c.b);
            c = new Color(1, 1, 1);
            trace(c.r, c.g, c.b);
        });

        test("Exposed Constants", function() {
            trace(Color.NAMES.aliceblue);
        });

        test("isColor", function() {
            var a = new Color();
            var b = new js.Object();
            trace(a.isColor, b.isColor);
        });

        test("set", function() {
            var a = new Color();
            var b = new Color(0.5, 0, 0);
            var c = new Color(0xFF0000);
            var d = new Color(0, 1.0, 0);
            var e = new Color(0.5, 0.5, 0.5);

            a.set(b);
            trace(a.equals(b));

            a.set(0xFF0000);
            trace(a.equals(c));

            a.set("rgb(0,255,0)");
            trace(a.equals(d));

            a.set(0.5, 0.5, 0.5);
            trace(a.equals(e));
        });

        test("setScalar", function() {
            var c = new Color();
            c.setScalar(0.5);
            trace(c.r, c.g, c.b);
        });

        test("setHex", function() {
            var c = new Color();
            c.setHex(0xFA8072);
            trace(c.getHex(), c.r, c.g, c.b);
        });

        test("setRGB", function() {
            var c = new Color();
            c.setRGB(0.3, 0.5, 0.7);
            trace(c.r, c.g, c.b);
        });

        test("setHSL", function() {
            var c = new Color();
            var hsl = { h: 0, s: 0, l: 0 };
            c.setHSL(0.75, 1.0, 0.25);
            c.getHSL(hsl);
            trace(hsl.h, hsl.s, hsl.l);
        });

        test("setStyle", function() {
            var a = new Color();
            var b = new Color(8 / 255, 25 / 255, 178 / 255);
            a.setStyle("rgb(8,25,178)");
            trace(a.equals(b));

            b = new Color(8 / 255, 25 / 255, 178 / 255);
            a.setStyle("rgba(8,25,178,200)");
            trace(a.equals(b));

            var hsl = { h: 0, s: 0, l: 0 };
            a.setStyle("hsl(270,50%,75%)");
            a.getHSL(hsl);
            trace(hsl.h, hsl.s, hsl.l);

            a.setStyle("#F8A");
            trace(a.r, a.g, a.b);

            a.setStyle("#F8ABC1");
            trace(a.r, a.g, a.b);

            a.setStyle("aliceblue");
            trace(a.r, a.g, a.b);
        });

        test("setColorName", function() {
            var c = new Color();
            c.setColorName("aliceblue");
            trace(c.getHex());
        });

        test("clone", function() {
            var c = new Color("teal");
            var c2 = c.clone();
            trace(c2.getHex());
        });

        test("copy", function() {
            var a = new Color("teal");
            var b = new Color();
            b.copy(a);
            trace(b.r, b.g, b.b);
        });

        test("copySRGBToLinear", function() {
            var c = new Color();
            var c2 = new Color();
            c2.setRGB(0.3, 0.5, 0.9);
            c.copySRGBToLinear(c2);
            trace(c.r, c.g, c.b);
        });

        test("copyLinearToSRGB", function() {
            var c = new Color();
            var c2 = new Color();
            c2.setRGB(0.09, 0.25, 0.81);
            c.copyLinearToSRGB(c2);
            trace(c.r, c.g, c.b);
        });

        test("convertSRGBToLinear", function() {
            var c = new Color();
            c.setRGB(0.3, 0.5, 0.9);
            c.convertSRGBToLinear();
            trace(c.r, c.g, c.b);
        });

        test("convertLinearToSRGB", function() {
            var c = new Color();
            c.setRGB(4, 9, 16);
            c.convertLinearToSRGB();
            trace(c.r, c.g, c.b);
        });

        test("getHex", function() {
            var c = new Color("red");
            var res = c.getHex();
            trace(res);
        });

        test("getHexString", function() {
            var c = new Color("tomato");
            var res = c.getHexString();
            trace(res);
        });

        test("getHSL", function() {
            var c = new Color(0x80ffff);
            var hsl = { h: 0, s: 0, l: 0 };
            c.getHSL(hsl);
            trace(hsl.h, hsl.s, hsl.l);
        });

        test("getRGB", function() {
            var c = new Color("plum");
            var t = { r: 0, g: 0, b: 0 };
            c.getRGB(t);
            trace(t.r, t.g, t.b);
        });

        test("getStyle", function() {
            var c = new Color("plum");
            trace(c.getStyle());
        });

        test("offsetHSL", function() {
            var a = new Color("hsl(120,50%,50%)");
            var b = new Color(0.36, 0.84, 0.648);
            a.offsetHSL(0.1, 0.1, 0.1);
            trace(a.r, a.g, a.b);
        });

        test("add", function() {
            var a = new Color(0x0000FF);
            var b = new Color(0xFF0000);
            var c = new Color(0xFF00FF);
            a.add(b);
            trace(a.equals(c));
        });

        test("addColors", function() {
            var a = new Color(0x0000FF);
            var b = new Color(0xFF0000);
            var c = new Color(0xFF00FF);
            var d = new Color();
            d.addColors(a, b);
            trace(d.equals(c));
        });

        test("addScalar", function() {
            var a = new Color(0.1, 0.0, 0.0);
            var b = new Color(0.6, 0.5, 0.5);
            a.addScalar(0.5);
            trace(a.equals(b));
        });

        test("sub", function() {
            var a = new Color(0x0000CC);
            var b = new Color(0xFF0000);
            var c = new Color(0x0000AA);
            a.sub(b);
            trace(a.getHex());
            a.sub(c);
            trace(a.getHex());
        });

        test("multiply", function() {
            var a = new Color(1, 0, 0.5);
            var b = new Color(0.5, 1, 0.5);
            var c = new Color(0.5, 0, 0.25);
            a.multiply(b);
            trace(a.equals(c));
        });

        test("multiplyScalar", function() {
            var a = new Color(0.25, 0, 0.5);
            var b = new Color(0.5, 0, 1);
            a.multiplyScalar(2);
            trace(a.equals(b));
        });

        test("lerp", function() {
            var c = new Color();
            var c2 = new Color();
            c.setRGB(0, 0, 0);
            c.lerp(c2, 0.2);
            trace(c.r, c.g, c.b);
        });

        test("equals", function() {
            var a = new Color(0.5, 0.0, 1.0);
            var b = new Color(0.5, 1.0, 0.0);
            trace(a.r, a.g, a.b);
            trace(b.r, b.g, b.b);
            trace(a.equals(b));
            a.copy(b);
            trace(a.r, a.g, a.b);
            trace(a.equals(b));
        });

        test("fromArray", function() {
            var a = new Color();
            var array = [0.5, 0.6, 0.7, 0, 1, 0];
            a.fromArray(array);
            trace(a.r, a.g, a.b);
            a.fromArray(array, 3);
            trace(a.r, a.g, a.b);
        });

        test("toArray", function() {
            var r = 0.5, g = 1.0, b = 0.0;
            var a = new Color(r, g, b);
            var array = a.toArray();
            trace(array[0], array[1], array[2]);
            array = [];
            a.toArray(array);
            trace(array[0], array[1], array[2]);
            array = [];
            a.toArray(array, 1);
            trace(array[0], array[1], array[2], array[3]);
        });

        test("toJSON", function() {
            var a = new Color(0.0, 0.0, 0.0);
            var b = new Color(0.0, 0.5, 0.0);
            var c = new Color(1.0, 0.0, 0.0);
            var d = new Color(1.0, 1.0, 1.0);
            trace(a.toJSON(), b.toJSON(), c.toJSON(), d.toJSON());
        });

        test("copyHex", function() {
            var c = new Color();
            var c2 = new Color(0xF5FFFA);
            c.copy(c2);
            trace(c.getHex(), c2.getHex());
        });

        test("copyColorString", function() {
            var c = new Color();
            var c2 = new Color("ivory");
            c.copy(c2);
            trace(c.getHex(), c2.getHex());
        });

        test("setWithNum", function() {
            var c = new Color();
            c.set(0xFF0000);
            trace(c.r, c.g, c.b);
        });

        test("setWithString", function() {
            var c = new Color();
            c.set("silver");
            trace(c.getHex());
        });

        test("setStyleRGBRed", function() {
            var c = new Color();
            c.setStyle("rgb(255,0,0)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleRGBARed", function() {
            var c = new Color();
            c.setStyle("rgba(255,0,0,0.5)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleRGBRedWithSpaces", function() {
            var c = new Color();
            c.setStyle("rgb( 255 , 0,   0 )");
            trace(c.r, c.g, c.b);
        });

        test("setStyleRGBARedWithSpaces", function() {
            var c = new Color();
            c.setStyle("rgba( 255,  0,  0  , 1 )");
            trace(c.r, c.g, c.b);
        });

        test("setStyleRGBPercent", function() {
            var c = new Color();
            c.setStyle("rgb(100%,50%,10%)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleRGBAPercent", function() {
            var c = new Color();
            c.setStyle("rgba(100%,50%,10%, 0.5)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleRGBPercentWithSpaces", function() {
            var c = new Color();
            c.setStyle("rgb( 100% ,50%  , 10% )");
            trace(c.r, c.g, c.b);
        });

        test("setStyleRGBAPercentWithSpaces", function() {
            var c = new Color();
            c.setStyle("rgba( 100% ,50%  ,  10%, 0.5 )");
            trace(c.r, c.g, c.b);
        });

        test("setStyleHSLRed", function() {
            var c = new Color();
            c.setStyle("hsl(360,100%,50%)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleHSLARed", function() {
            var c = new Color();
            c.setStyle("hsla(360,100%,50%,0.5)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleHSLRedWithSpaces", function() {
            var c = new Color();
            c.setStyle("hsl(360,  100% , 50% )");
            trace(c.r, c.g, c.b);
        });

        test("setStyleHSLARedWithSpaces", function() {
            var c = new Color();
            c.setStyle("hsla( 360,  100% , 50%,  0.5 )");
            trace(c.r, c.g, c.b);
        });

        test("setStyleHSLRedWithDecimals", function() {
            var c = new Color();
            c.setStyle("hsl(360,100.0%,50.0%)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleHSLARedWithDecimals", function() {
            var c = new Color();
            c.setStyle("hsla(360,100.0%,50.0%,0.5)");
            trace(c.r, c.g, c.b);
        });

        test("setStyleHexSkyBlue", function() {
            var c = new Color();
            c.setStyle("#87CEEB");
            trace(c.getHex());
        });

        test("setStyleHexSkyBlueMixed", function() {
            var c = new Color();
            c.setStyle("#87cEeB");
            trace(c.getHex());
        });

        test("setStyleHex2Olive", function() {
            var c = new Color();
            c.setStyle("#F00");
            trace(c.getHex());
        });

        test("setStyleHex2OliveMixed", function() {
            var c = new Color();
            c.setStyle("#f00");
            trace(c.getHex());
        });

        test("setStyleColorName", function() {
            var c = new Color();
            c.setStyle("powderblue");
            trace(c.getHex());
        });

        test("iterable", function() {
            var c = new Color(0.5, 0.75, 1);
            var array = [ ...c ];
            trace(array[0], array[1], array[2]);
        });
    }
}

class ColorManagementTest {
    static function main() {
        module("Maths > ColorManagement", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });

        test("something", function() {
            // test something
        });
    }
}

class DisplayP3ColorSpaceTest {
    static function main() {
        module("Maths > DisplayP3ColorSpace", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });
test("something", function() {
    // test something
});
}

class SRGBColorSpaceTest {
    static function main() {
        module("Maths > SRGBColorSpace", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });

        test("something", function() {
            // test something
        });
    }
}

class ConstantsTest {
    static function main() {
        module("Maths > Constants", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });

        test("something", function() {
            // test something
        });
    }
}

class MathConstantsTest {
    static function main() {
        module("Maths > MathConstants", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });

        test("something", function() {
            // test something
        });
    }
}

class ConsoleWrapperTest {
    static function main() {
        module("Maths > ConsoleWrapper", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });

        test("something", function() {
            // test something
        });
    }
}

class UtilsTest {
    static function main() {
        module("Maths > Utils", {
            setup: function() {
                // setup
            },
            teardown: function() {
                // teardown
            }
        });

        test("something", function() {
            // test something
        });
    }
}

class Main {
    static function main() {
        ColorTest.main();
        ColorManagementTest.main();
        DisplayP3ColorSpaceTest.main();
        SRGBColorSpaceTest.main();
        ConstantsTest.main();
        MathConstantsTest.main();
        ConsoleWrapperTest.main();
        UtilsTest.main();
    }
}

Main.main();