package three.js.examples.jsm.loaders;

import three.math.Vector2;

class SVGLoader_func_part3 {
    static function pointsToStrokeWithBuffers(points:Array<Vector2>, style:Dynamic, arcDivisions:Int, minDistance:Float, vertices:Array<Float>, normals:Array<Float>, uvs:Array<Float>, vertexOffset:Int):Int {
        // ...
    }

    static function getNormal(p1:Vector2, p2:Vector2, result:Vector2):Vector2 {
        result.subVectors(p2, p1);
        return result.set(-result.y, result.x).normalize();
    }

    static function addVertex(position:Vector2, u:Float, v:Float) {
        // ...
    }

    static function makeCircularSector(center:Vector2, p1:Vector2, p2:Vector2, u:Float, v:Float) {
        // ...
    }

    static function makeSegmentTriangles() {
        // ...
    }

    static function makeSegmentWithBevelJoin(joinIsOnLeftSide:Bool, innerSideModified:Bool, u:Float) {
        // ...
    }

    static function createSegmentTrianglesWithMiddleSection(joinIsOnLeftSide:Bool, innerSideModified:Bool) {
        // ...
    }

    static function addCapGeometry(center:Vector2, p1:Vector2, p2:Vector2, joinIsOnLeftSide:Bool, start:Bool, u:Float) {
        // ...
    }

    static function removeDuplicatedPoints(points:Array<Vector2>):Array<Vector2> {
        // ...
    }
}