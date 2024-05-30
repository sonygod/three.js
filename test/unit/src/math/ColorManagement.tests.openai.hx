package three.math;

import haxe.unit.TestCase;

class ColorManagementTests extends TestCase {
	override public function test() {
		describe("Maths", () => {
			describe("ColorManagement", () => {
				// PROPERTIES
				it("enabled", () => {
					assertEquals(ColorManagement.enabled, true, 'ColorManagement.enabled is true by default.');
				});

				it("workingColorSpace", () => {
					throw new haxe.unit.TestCase.Timeout("todo: implement");
				});

				// PUBLIC
				it("convert", () => {
					throw new haxe.unit.TestCase.Timeout("todo: implement");
				});

				it("fromWorkingColorSpace", () => {
					throw new haxe.unit.TestCase.Timeout("todo: implement");
				});

				it("toWorkingColorSpace", () => {
					throw new haxe.unit.TestCase.Timeout("todo: implement");
				});

				// EXPORTED FUNCTIONS
				it("SRGBToLinear", () => {
					throw new haxe.unit.TestCase.Timeout("todo: implement");
				});

				it("LinearToSRGB", () => {
					throw new haxe.unit.TestCase.Timeout("todo: implement");
				});
			});
		});
	}
}