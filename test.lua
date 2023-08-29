
local iso = require("isometrih")(term.current())

local current_path = shell.getRunningProgram()
local current_dir  = fs.getDir(current_path)

function iso.load()
    iso.load_tile(
        {path=fs.combine(current_dir,"iso/blocks/grass.nfp"),tile_name="grass"},
        {path=fs.combine(current_dir,"iso/blocks/sand.nfp"), tile_name="sand"}
    )

    iso.set_compression_level(0.571)

    iso.fill_tiles("grass",1,1,1,20,-4,20)
    iso.fill_tiles(nil,2,1,2,19,-3,19)
    iso.set_tile("sand",2,1,2)
end

function iso.update()
    iso.pause_render()
    iso.get_tiles(function(tile,x,y,z)
        if tile == "sand" and not iso.get_tile(x,y-0.5,z) then
            iso.move_tile(x,y,z,x,y-0.5,z)
        end
    end)
    iso.resume_render()

    sleep(0.5)
end


iso.run()
