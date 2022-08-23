local pixelbox = require("pixelbox")
local function init(terminal)
    local box = pixelbox.new(terminal)
    terminal.clear()
    local i = 1
    local j = -1
    local press_amount = 0.5
    local update_rate = 0.2

    local screen_width,screen_height = terminal.getSize()

    screen_width = screen_width * 2
    screen_height = screen_height * 3

    local grid = {n=0,start=1}
    local tiles = {}
    local loaded_tiles = {}

    local grid_offset_x = 0
    local grid_offset_y = 0
    local grid_offset_z = 0
    local screen_offset_x = 0
    local screen_offset_y = 0

    local screen_offset_scripts = {}
    local grid_offset_scripts = {}

    local function init_grid_point(x,y,z)
        if not grid[y] then
            grid[y] = {}
            if y > 0 then
                grid[y].n = y
                grid[y].start = 1
            else
                grid[y].n = 1
                grid[y].start = y
            end
        end
        if not grid[y][z] then
            grid[y][z] = {}
            if z > 0 then
                grid[y][z].n = z
                grid[y][z].start = 1
            else
                grid[y][z].n = 1
                grid[y][z].start = z
            end
        end
        if not grid[y][z][x] then
            grid[y][z][x] = {}
            if x > 0 then
                grid[y][z][x].n = x
                grid[y][z][x].start = 1
            else
                grid[y][z][x].n = 1
                grid[y][z][x].start = x
            end
        end
        if y > grid.n then grid.n = y end
        if y < grid.start then grid.start = y end
        if z > grid[y].n then grid[y].n = z end
        if z < grid[y].start then grid[y].start = z end
        if x > grid[y][z].n then grid[y][z].n = x end
        if x < grid[y][z].start then grid[y][z].start = x end
    end

    local function load_images()
        for k,v in pairs(tiles) do
            local file = fs.open(v.path,"r")
            local data = file.readAll()
            file.close()
            local height = 0
            local width = 0
            local image = {}
            for line in data:gmatch("([^\n]+)") do
                local temp_w = 0
                height = height + 1
                if not image[height] then image[height] = {} end
                for color in line:gmatch(".") do
                    temp_w = temp_w + 1
                    if color ~= " " then
                        image[height][temp_w] = 2^tonumber(color,16)
                    end
                end
                width = math.max(width,temp_w)
            end
            loaded_tiles[v.tile_name] = {tex=image,w=width,h=height}
        end
    end

    local function draw_image(image,x,y,buffer,tile_x,tile_y,tile_z,sprite)
        for img_y=1,image.h do
            for img_x=1,image.w do
                local offset_x = math.ceil(x + img_x - 0.5)
                local offset_y = math.ceil(y + img_y - 0.5)
                local c = image.tex[img_y][img_x]
                if c then
                    local screen_x = math.ceil(offset_x/2)
                    local screen_y = math.ceil(offset_y/3)
                    if not buffer[screen_y] then buffer[screen_y] = {} end
                    buffer[screen_y][screen_x] = {
                        x=tile_x,
                        y=tile_y,
                        z=tile_z,
                        tex_x = img_x,
                        tex_y = img_y,
                        tile = sprite
                    }
                    box:set_pixel(offset_x, offset_y, c, 1, true)
                end
            end
        end
    end

    local function draw_grid()
        local coordinate_grid = {}
        for y=grid.start or 1,grid.n do
            local layer = grid[y]
            for z=(layer or {start=1}).start,(layer or {n=0}).n or 0 do
                local row = layer[z]
                for x=(row or {start=1}).start,(row or {n=0}).n do
                    local sprite_name = row[x]
                    local sprites = {}
                    if type(sprite_name) == "string" then sprites = {sprite_name}
                    elseif type(sprite_name) == "table" then sprites = sprite_name end
                    for k,sprite in ipairs(sprites or {}) do
                        local sprite = loaded_tiles[sprite]
                        if sprite then
                            local offset_x = grid_offset_x
                            local offset_y = grid_offset_y
                            local offset_z = grid_offset_z
                            if grid_offset_scripts[x] and grid_offset_scripts[x][y] and type(grid_offset_scripts[x][y][z]) == "function" then
                                local ox,oy,oz = grid_offset_scripts[x][y][z](x,y,z)
                                if ox then offset_x = offset_x + ox end
                                if oy then offset_y = offset_y + oy end
                                if oz then offset_z = offset_z + oz end
                            end
                            local screen_x = (x + offset_x)*i + (z + offset_z)*j
                            local screen_y = (x + offset_x)*press_amount + (z + offset_z)*press_amount - (y + offset_y) + 1
                            if screen_offset_scripts[x] and screen_offset_scripts[x][y] and type(screen_offset_scripts[x][y][z]) == "function" then
                                screen_x,screen_y = screen_offset_scripts[x][y][z](screen_x,screen_y)
                            end
                            local tex_x = (screen_x + screen_offset_x)*sprite.w/2 - sprite.w/2 + screen_width/2 - 1
                            local tex_y = (screen_y + screen_offset_y)*sprite.h/2
                            draw_image(sprite,tex_x,tex_y,coordinate_grid,x,y,z,sprite)
                        end
                    end
                end
            end
        end
        return coordinate_grid
    end

    local methods = {}
    local data = {}
    local last_map

    function methods.run()

        local run = true

        if type(data.load) == "function" then
            xpcall(data.load,function(err)
                run = false
                if err then
                    printError("Error during isometrih.load: "..tostring(err))
                end
            end)
        end
        load_images()

        local ran = 0

        local update_graphics = coroutine.create(function()
            while true do
                local screen_data = draw_grid()
                coroutine.yield("return",true,screen_data)
                if type(data.draw) == "function" then
                    xpcall(function() data.draw(box) end,function(err)
                        run = false
                        if err then
                            printError("Error during isometrih.update "..tostring(err))
                        end
                    end)
                end
                box:push_updates()
                box:draw()
                box:clear(terminal.getBackgroundColor())
                ran = ran + 1
                sleep(update_rate)
            end
        end)

        local filter

        coroutine.resume(update_graphics)
        coroutine.resume(update_graphics)

        while run and coroutine.status(update_graphics) ~= "dead" do
            local ev = table.pack(os.pullEventRaw())
            if ev[1] == "terminate" then break end
            if not filter or ev[1] == "filter" then
                local ok, ret, is_map, map = coroutine.resume(update_graphics,table.unpack(ev,1,ev.n))
                if not ok and coroutine.status(update_graphics) == "dead" then
                    run = false
                    printError("Error during runtime: "..ret)
                end
                if is_map and ret == "return" then last_map = map coroutine.resume(update_graphics,table.unpack(ev,1,ev.n)) end
                if is_map and ret == "return" and type(data.update) == "function" then
                    xpcall(function() data.update(map) end,function(err)
                        run = false
                        if err then
                            printError("Error during isometrih.update "..tostring(err))
                        end
                    end)
                end
            end
            if data.on_event and last_map then
                xpcall(function() data.on_event(last_map,table.unpack(ev,1,ev.n)) end,function(err)
                    run = false
                    if err then
                        printError("Error during isometrih.on_event "..tostring(err))
                    end
                end)
            end
        end
    end

    function methods.set_block(tile,x,y,z)
        init_grid_point(x,y,z)
        grid[y][z][x] = tile
    end

    function methods.get_block(x,y,z)
        return grid[y] and grid[y][z] and grid[y][z][x]
    end

    function methods.get_tiles(filter)
        local found = {}
        for y=grid.start or 1,grid.n do
            local layer = grid[y]
            for z=(layer or {start=1}).start,(layer or {n=0}).n or 0 do
                local row = layer[z]
                for x=(row or {start=1}).start,(row or {n=0}).n do
                    local sprite_name = row[x]
                    local sprites = {}
                    if type(sprite_name) == "string" then sprites = {sprite_name}
                    elseif type(sprite_name) == "table" then sprites = sprite_name end
                    for k,sprite in ipairs(sprites or {}) do
                        if filter(sprite) then
                            found[#found+1] = {x=x,y=y,z=z,sprite=sprite}
                        end
                    end
                end
            end
        end
        return found
    end

    function methods.fill_blocks(tile,start_x,start_y,start_z,end_x,end_y,end_z)
        if start_x > end_x then start_x,end_x = end_x,start_x end
        if start_y > end_y then start_y,end_y = end_x,start_y end
        if start_z > end_z then start_z,end_z = end_x,start_z end
        for x=start_x,end_x do
            for y=start_y,end_y do
                for z=start_z,end_z do
                    init_grid_point(x,y,z)
                    grid[y][z][x] = tile
                end
            end
        end
    end

    function methods.reload_textures()
        tiles = {}
        load_images()
    end

    function methods.load_tile(...)
        for k,v in pairs({...}) do
            table.insert(tiles,v)
        end
    end

    function methods.unload_tiles()
        loaded_tiles = {}
    end

    function methods.delete_tile(...)
        for k,v in pairs({...}) do
            tiles[v] = nil
        end
        load_images()
    end

    function methods.set_screen_offset_script(x,y,z,f)
        if not screen_offset_scripts[x] then screen_offset_scripts[x] = {} end
        if not screen_offset_scripts[x][y] then screen_offset_scripts[x][y] = {} end
        screen_offset_scripts[x][y][z] = f
    end

    function methods.del_screen_offset_script(x,y,z)
        if not screen_offset_scripts[x] then screen_offset_scripts[x] = {} end
        if not screen_offset_scripts[x][y] then screen_offset_scripts[x][y] = {} end
        screen_offset_scripts[x][y][z] = nil
    end
    
    function methods.del_screen_offset_scripts()
        screen_offset_scripts = {}
    end

    function methods.set_grid_offset_script(x,y,z,f)
        if not grid_offset_scripts[x] then grid_offset_scripts[x] = {} end
        if not grid_offset_scripts[x][y] then grid_offset_scripts[x][y] = {} end
        grid_offset_scripts[x][y][z] = f
    end

    function methods.del_grid_offset_script(x,y,z)
        if not grid_offset_scripts[x] then grid_offset_scripts[x] = {} end
        if not grid_offset_scripts[x][y] then grid_offset_scripts[x][y] = {} end
        grid_offset_scripts[x][y][z] = nil
    end

    function methods.del_grid_offset_scripts()
        grid_offset_scripts = {}
    end

    function methods.set_jhat(n)
        j = -n
    end

    function methods.set_ihat(n)
        i = n
    end

    function methods.set_compression_level(n)
        press_amount = n
    end

    function methods.set_screen_offset(x,y)
        if type(x) == "number" then screen_offset_x = x end
        if type(y) == "number" then screen_offset_y = y end
    end

    function methods.set_grid_offset(x,y,z)
        if type(x) == "number" then grid_offset_x = x end
        if type(y) == "number" then grid_offset_y = y end
        if type(z) == "number" then grid_offset_z = z end
    end

    return setmetatable(data,{__index=methods})
end

return init
