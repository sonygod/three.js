import utest.Assert;
import three.cameras.OrthographicCamera;
import three.cameras.Camera;

class OrthographicCameraTests {
    public function new() {}

    public function testInheritance() {
        var object = new OrthographicCamera();
        Assert.isTrue(Std.is(object, Camera), 'OrthographicCamera extends from Camera');
    }

    public function testInstancing() {
        var object = new OrthographicCamera();
        Assert.notNull(object, 'Can instantiate an OrthographicCamera.');
    }

    public function testType() {
        var object = new OrthographicCamera();
        Assert.equals(object.type, 'OrthographicCamera', 'OrthographicCamera.type should be OrthographicCamera');
    }

    public function todoZoom() {
        Assert.fail('todo: zoom');
    }

    public function todoView() {
        Assert.fail('todo: view');
    }

    public function todoLeft() {
        Assert.fail('todo: left');
    }

    public function todoRight() {
        Assert.fail('todo: right');
    }

    public function todoTop() {
        Assert.fail('todo: top');
    }

    public function todoBottom() {
        Assert.fail('todo: bottom');
    }

    public function todoNear() {
        Assert.fail('todo: near');
    }

    public function todoFar() {
        Assert.fail('todo: far');
    }

    public function testIsOrthographicCamera() {
        var object = new OrthographicCamera();
        Assert.isTrue(object.isOrthographicCamera, 'OrthographicCamera.isOrthographicCamera should be true');
    }

    public function todoCopy() {
        Assert.fail('todo: copy');
    }

    public function todoSetViewOffset() {
        Assert.fail('todo: setViewOffset');
    }

    public function todoClearViewOffset() {
        Assert.fail('todo: clearViewOffset');
    }

    public function testUpdateProjectionMatrix() {
        var left = -1.0, right = 1.0, top = 1.0, bottom = -1.0, near = 1.0, far = 3.0;
        var cam = new OrthographicCamera(left, right, top, bottom, near, far);

        var pMatrix = cam.projectionMatrix.elements;

        Assert.equals(pMatrix[0], 2.0 / (right - left), 'm[0,0] === 2 / (r - l)');
        Assert.equals(pMatrix[5], 2.0 / (top - bottom), 'm[1,1] === 2 / (t - b)');
        Assert.equals(pMatrix[10], -2.0 / (far - near), 'm[2,2] === -2 / (f - n)');
        Assert.equals(pMatrix[12], -(left + right) / (right - left), 'm[3,0] === -(r+l/r-l)');
        Assert.equals(pMatrix[13], -(top + bottom) / (top - bottom), 'm[3,1] === -(t+b/b-t)');
        Assert.equals(pMatrix[14], -(far + near) / (far - near), 'm[3,2] === -(f+n/f-n)');
    }

    public function todoToJson() {
        Assert.fail('todo: toJSON');
    }

    public function testClone() {
        var left = -1.5, right = 1.5, top = 1.0, bottom = -1.0, near = 0.1, far = 42.0;
        var cam = new OrthographicCamera(left, right, top, bottom, near, far);

        var clonedCam = cam.clone();

        Assert.equals(cam.left, clonedCam.left, 'left is equal');
        Assert.equals(cam.right, clonedCam.right, 'right is equal');
        Assert.equals(cam.top, clonedCam.top, 'top is equal');
        Assert.equals(cam.bottom, clonedCam.bottom, 'bottom is equal');
        Assert.equals(cam.near, clonedCam.near, 'near is equal');
        Assert.equals(cam.far, clonedCam.far, 'far is equal');
        Assert.equals(cam.zoom, clonedCam.zoom, 'zoom is equal');
    }
}