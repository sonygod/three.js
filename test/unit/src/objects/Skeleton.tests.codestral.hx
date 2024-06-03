import three.objects.Skeleton;

class SkeletonTests {
    public static function main() {
        trace("Objects");
        trace("Skeleton");
        testInstancing();
        testDispose();
        // Add other test functions here
    }

    private static function testInstancing() {
        trace("Instancing");
        var object:Skeleton = new Skeleton();
        trace("Can instantiate a Skeleton: " + (object != null));
    }

    private static function testDispose() {
        trace("dispose");
        var object:Skeleton = new Skeleton();
        object.dispose();
    }

    // Add other test functions here
}