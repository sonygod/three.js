class GeometryParser {

    public var negativeMaterialIndices: Bool;

    public function new() {
        negativeMaterialIndices = false;
    }

    // Parse nodes in FBXTree.Objects.Geometry
    public function parse(deformers:Dynamic):Map<Int,Dynamic> {
        var geometryMap = new Map<Int,Dynamic>();

        if ('Geometry' in fbxTree.Objects) {
            var geoNodes = fbxTree.Objects.Geometry;

            for (nodeID in geoNodes) {
                var relationships = connections.get(parseInt(nodeID));
                var geo = this.parseGeometry(relationships, geoNodes[nodeID], deformers);

                geometryMap.set(parseInt(nodeID), geo);
            }
        }

        // report warnings

        if (this.negativeMaterialIndices === true) {
            trace('THREE.FBXLoader: The FBX file contains invalid (negative) material indices. The asset might not render as expected.');
        }

        return geometryMap;
    }

    // Parse single node in FBXTree.Objects.Geometry
    public function parseGeometry(relationships:Dynamic, geoNode:Dynamic, deformers:Dynamic):Dynamic {
        switch (geoNode.attrType) {
            case 'Mesh':
                return this.parseMeshGeometry(relationships, geoNode, deformers);
            case 'NurbsCurve':
                return this.parseNurbsGeometry(geoNode);
        }
    }

    // Parse single node mesh geometry in FBXTree.Objects.Geometry
    public function parseMeshGeometry(relationships:Dynamic, geoNode:Dynamic, deformers:Dynamic):Dynamic {
        // ... (same as JavaScript)
    }

    // Generate a BufferGeometry from a node in FBXTree.Objects.Geometry
    public function genGeometry(geoNode:Dynamic, skeleton:Dynamic, morphTargets:Array<Dynamic>, preTransform:Dynamic):BufferGeometry {
        // ... (same as JavaScript)
    }

    // ... (other functions are the same as JavaScript)

}