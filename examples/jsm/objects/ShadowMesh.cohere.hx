import h3d.Matrix4;
import h3d.Mesh;
import h3d.MeshBasicMaterial;
import h3d.StencilFunc.Equal;
import h3d.StencilOp.Increment;

/**
 * A shadow Mesh that follows a shadow-casting Mesh in the scene, but is confined to a single plane.
 */
class ShadowMesh extends Mesh {
    public var isShadowMesh:Bool;
    private var _shadowMatrix:Matrix4;
    public var meshMatrix:Matrix4;

    public function new(mesh:Mesh) {
        super(mesh.geometry, null);
        var shadowMaterial = MeshBasicMaterial({
            color: 0x000000,
            transparent: true,
            opacity: 0.6,
            depthWrite: false,
            stencilWrite: true,
            stencilFunc: Equal,
            stencilRef: 0,
            stencilZPass: Increment
        });
        this.material = shadowMaterial;
        this.isShadowMesh = true;
        this.meshMatrix = mesh.matrixWorld;
        this.frustumCulled = false;
        this.matrixAutoUpdate = false;
    }

    public function update(plane:h3d.Plane, lightPosition4D:h3d.Vector4):Void {
        // based on https://www.opengl.org/archives/resources/features/StencilTalk/tsld021.htm
        var dot = plane.normal.x * lightPosition4D.x +
                  plane.normal.y * lightPosition4D.y +
                  plane.normal.z * lightPosition4D.z +
                  -plane.constant * lightPosition4D.w;

        var sme = _shadowMatrix.elements;

        sme[0] = dot - lightPosition4D.x * plane.normal.x;
        sme[4] = -lightPosition4D.x * plane.normal.y;
        sme[8] = -lightPosition4D.x * plane.normal.z;
        sme[12] = -lightPosition4D.x * -plane.constant;

        sme[1] = -lightPosition4D.y * plane.normal.x;
        sme[5] = dot - lightPosition4D.y * plane.normal.y;
        sme[9] = -lightPosition4D.y * plane.normal.z;
        sme[13] = -lightPosition4D.y * -plane.constant;

        sme[2] = -lightPosition4D.z * plane.normal.x;
        sme[6] = -lightPosition4D.z * plane.normal.y;
        sme[10] = dot - lightPosition4D.z * plane.normal.z;
        sme[14] = -lightPosition4D.z * -plane.constant;

        sme[3] = -lightPosition4D.w * plane.normal.x;
        sme[7] = -lightPosition4D.w * plane.normal.y;
        sme[11] = -lightPosition4D.w * plane.normal.z;
        sme[15] = dot - lightPosition4D.w * -plane.constant;

        this.matrix.multiply(_shadowMatrix, this.meshMatrix);
    }
}