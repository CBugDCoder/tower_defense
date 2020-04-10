-- Look for required things in
package.path = "../?.lua;" .. package.path

function get_base_pos(id)
	id = (id % (60*60))-math.floor(id/(60*60))
	local x = ((id/60)-(math.floor(id/60)))*60
	local z = math.floor(id/60)
	x = x*1000-30000
	z = z*1000-30000
	return {x=x,z=z,y=15000}
end

-- Tests
describe("base_pos", function()
	it("is accurate", function()
		local base_pos = get_base_pos(1830)
		assert.equals(0, base_pos.x)
		assert.equals(15000, base_pos.y)
		assert.equals(0, base_pos.z)
	end)

	it("functions after looping", function()
		local base_pos = get_base_pos(3601)
		assert.equals(-30000, base_pos.x)
		assert.equals(15000, base_pos.y)
		assert.equals(-30000, base_pos.z)
	end)
end) 

