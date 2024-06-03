class GeometryParser {

    public var negativeMaterialIndices:Bool = false;

    public function new() {
        // Constructor
    }

    public function parse(deformers:Dynamic):Map<Int, Dynamic> {
        var geometryMap = new Map<Int, Dynamic>();

        if (Std.is(fbxTree.Objects, "Geometry")) {
            var geoNodes = fbxTree.Objects.Geometry;

            for (nodeID in Reflect.fields(geoNodes)) {
                var relationships = connections.get(Std.parseInt(nodeID));
                var geo = this.parseGeometry(relationships, geoNodes[nodeID], deformers);

                geometryMap.set(Std.parseInt(nodeID), geo);
            }
        }

        if (this.negativeMaterialIndices == true) {
            trace("THREE.FBXLoader: The FBX file contains invalid (negative) material indices. The asset might not render as expected.");
        }

        return geometryMap;
    }

    private function parseGeometry(relationships:Dynamic, geoNode:Dynamic, deformers:Dynamic):Dynamic {
        switch (geoNode.attrType) {
            case 'Mesh':
                return this.parseMeshGeometry(relationships, geoNode, deformers);
            case 'NurbsCurve':
                return this.parseNurbsGeometry(geoNode);
        }
        return null;
    }

    // Continue with the rest of the methods...
}