package three.test.unit.src;

import three.Constants;

class ConstantsTests {
    public function new() {}

    public function testDefaultValues() {
        Assert.equals(Constants.MOUSE, {LEFT: 0, MIDDLE: 1, RIGHT: 2, ROTATE: 0, DOLLY: 1, PAN: 2}, 'MOUSE equal {LEFT: 0, MIDDLE: 1, RIGHT: 2, ROTATE: 0, DOLLY: 1, PAN: 2}');
        Assert.equals(Constants.TOUCH, {ROTATE: 0, PAN: 1, DOLLY_PAN: 2, DOLLY_ROTATE: 3}, 'TOUCH equal {ROTATE: 0, PAN: 1, DOLLY_PAN: 2, DOLLY_ROTATE: 3}');

        Assert.equals(Constants.CullFaceNone, 0, 'CullFaceNone equal 0');
        Assert.equals(Constants.CullFaceBack, 1, 'CullFaceBack equal 1');
        Assert.equals(Constants.CullFaceFront, 2, 'CullFaceFront is equal to 2');
        Assert.equals(Constants.CullFaceFrontBack, 3, 'CullFaceFrontBack is equal to 3');

        // ... (rest of the asserts)

        Assert.equals(Constants.GLSL1, '100', 'GLSL1 is equal to 100');
        Assert.equals(Constants.GLSL3, '300 es', 'GLSL3 is equal to 300 es');
    }
}