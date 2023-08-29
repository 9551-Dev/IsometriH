local pixelbox = require("pixelbox_lite")
local expect   = require("cc.expect").expect

local function init(terminal)
    expect(1,terminal,"table")
    local box = pixelbox.new(terminal)
    terminal.clear()
    local update_rate = 0.05

    local i = 1
    local j = -1
    local press_amount = 0.5

    local screen_width,screen_height = terminal.getSize()

    screen_width = screen_width * 2
    screen_height = screen_height * 3

    local grid = {}
    local tiles = {}
    local loaded_tiles = {}

    local grid_offset_x = 0
    local grid_offset_y = 0
    local grid_offset_z = 0
    local screen_offset_x = 0
    local screen_offset_y = 0

    local screen_offset_scripts = {}
    local grid_offset_scripts = {}
    local tile_update_scripts = {}
    local tasks = {}

    local function init_grid_point(x,y,z)
        --[[if not grid[y] then
            grid[y] = {}
            if z > 0 then
                grid[y].n = z
                grid[y].start = 1
            else
                grid[y].n = 1
                grid[y].start = z
            end
        end
        if not grid[y][z] then
            grid[y][z] = {}
            if z > 0 then
                grid[y][z].n = x
                grid[y][z].start = 1
            else
                grid[y][z].n = 1
                grid[y][z].start = x
            end
        end
        if y > grid.n then grid.n = y end
        if y < grid.start then grid.start = y end
        if z > grid[y].n then grid[y].n = z end
        if z < grid[y].start then grid[y].start = z end
        if x > grid[y][z].n then grid[y][z].n = x end
        if x < grid[y][z].start then grid[y][z].start = x end]]
        if not grid[y] then grid[y] = {} end
        if not grid[y][z] then grid[y][z] = {} end
    end

    local function load_images()
        for k,v in pairs(tiles) do
            if type(v.tile_name) ~= "string" then error("Tile name must be a string",2) end
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

    local function keys(tbl)
        local keys = {}
        for k,_ in pairs(tbl) do
            table.insert(keys,k)
        end
        return keys
    end

    local function iterate_order(tbl,reversed)
        local indice = 0
        local keys = keys(tbl)
        table.sort(keys, function(a, b)
            if reversed then return b<a
            else return a<b end
        end)
        return function()
            indice = indice + 1
            if tbl[keys[indice]] then return keys[indice],tbl[keys[indice]]
            else return end
        end
    end

    local function check_pixel_bounds(x,y)
        return x > 0 and x <= box.width*2 and y > 0 and y <= box.height*3
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

                    if check_pixel_bounds(offset_x,offset_y) then
                        box.CANVAS[offset_y][offset_x] = c
                    end
                end
            end
        end
    end

    local function draw_grid()
        local coordinate_grid = {}
        for y,layer in iterate_order(grid) do
            for z,row in iterate_order(layer) do
                for x,sprite_name in iterate_order(row) do
                    local sprites = {}
                    if type(sprite_name) == "string" then sprites = {sprite_name}
                    elseif type(sprite_name) == "table" then sprites = sprite_name end
                    for k,sprite in ipairs(sprites or {}) do
                        local sprite = loaded_tiles[sprite]
                        local has_offset_script = false
                        if sprite then
                            local offset_x = grid_offset_x
                            local offset_y = grid_offset_y
                            local offset_z = grid_offset_z
                            if tile_update_scripts[x] and tile_update_scripts[x][y] and type(tile_update_scripts[x][y][z]) == "function" then
                                tile_update_scripts[x][y][z](sprite,x,y,z)
                            end
                            if grid_offset_scripts[x] and grid_offset_scripts[x][y] and type(grid_offset_scripts[x][y][z]) == "function" then
                                has_offset_script = true
                                local ox,oy,oz = grid_offset_scripts[x][y][z](x,y,z)
                                if ox then offset_x = offset_x + ox end
                                if oy then offset_y = offset_y + oy end
                                if oz then offset_z = offset_z + oz end
                            end
                            local screen_x = (x + offset_x)*i + (z + offset_z)*j
                            local screen_y = (x + offset_x)*press_amount + (z + offset_z)*press_amount - (y + offset_y) + 1
                            if screen_offset_scripts[x] and screen_offset_scripts[x][y] and type(screen_offset_scripts[x][y][z]) == "function" then
                                has_offset_script = true
                                screen_x,screen_y = screen_offset_scripts[x][y][z](screen_x,screen_y)
                            end
                            local tex_x = (screen_x + screen_offset_x)*sprite.w/2 - sprite.w/2 + screen_width/2 - 1
                            local tex_y = (screen_y + screen_offset_y)*sprite.h/2
                            if not (grid[y+1] and grid[y+1][z] and grid[y+1][z][x] and layer[z+1] and layer[z+1][x] and row[x+1]) or has_offset_script then
                                draw_image(sprite,tex_x,tex_y,coordinate_grid,x,y,z,sprite)
                            end
                        end
                    end
                end
            end
            os.queueEvent("yield")
            os.pullEvent ("yield")
        end
        return coordinate_grid
    end

    local methods = {}
    local data = {}

    local render_enabled = true

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

        local screen_data
        local sd_change = false

        local update_graphics = coroutine.create(function()
            while true do
                if render_enabled then
                    screen_data = draw_grid()
                    sd_change = true
                    if type(data.draw) == "function" then
                        xpcall(function() data.draw(box) end,function(err)
                            run = false
                            if err then
                                printError("Error during isometrih.update: "..tostring(err))
                            end
                        end)
                    end
                    box:render()
                    box:clear (terminal.getBackgroundColor())
                end
                sleep(update_rate)
            end
        end)

        local on_event_thread = coroutine.create(function()
            while true do
                local ev = table.pack(os.pullEventRaw())
                if data.on_event and screen_data then
                    xpcall(function() data.on_event(screen_data,table.unpack(ev,1,ev.n)) end,function(err)
                        run = false
                        if err then
                            printError("Error during isometrih.on_event: "..tostring(err))
                        end
                    end)
                end
            end
        end)

        local update_thread = coroutine.create(function()
            while true do
                local ev = table.pack(os.pullEventRaw())
                if sd_change and data.update then
                    sd_change = false
                    xpcall(function() data.update(screen_data,table.unpack(ev,1,ev.n)) end,function(err)
                        run = false
                        if err then
                            printError("Error during isometrih.update "..tostring(err))
                        end
                    end)
                end
            end
        end)

        local ok1,filter_1 = coroutine.resume(update_graphics)
        local ok2,filter_2 = coroutine.resume(on_event_thread)
        local ok3,filter_3 = coroutine.resume(update_thread)

        if not ok1 then printError("Error during runtime: "..tostring(filter_1)) end
        if not ok2 then printError("Error during runtime: "..tostring(filter_2)) end
        if not ok3 then printError("Error during runtime: "..tostring(filter_3)) end

        while run and coroutine.status(update_graphics) ~= "dead" do
            local ev = table.pack(os.pullEvent())
            if ev[1] == "terminate" then break end
            if not filter_1 or ev[1] == filter_1 then
                local ok, ret = coroutine.resume(update_graphics,table.unpack(ev,1,ev.n))
                if ok then filter_1 = ret end
                if not ok and coroutine.status(update_graphics) == "dead" then
                    run = false
                    printError("Error during runtime: "..tostring(ret))
                end
            end
            if not filter_2 or ev[1] == filter_2 then
                local ok, ret = coroutine.resume(on_event_thread,table.unpack(ev,1,ev.n))
                if ok then filter_2 = ret end
                if not ok and coroutine.status(on_event_thread) == "dead" then
                    run = false
                    printError("Error during isometrih.on_event: "..tostring(ret))
                end
            end
            if not filter_3 or ev[1] == filter_3 then
                local ok, ret = coroutine.resume(update_thread,table.unpack(ev,1,ev.n))
                if ok then filter_3 = ret end
                if not ok and coroutine.status(update_thread) == "dead" then
                    run = false
                    printError("Error during isometrih.update: "..tostring(ret))
                end
            end
            for k,v in pairs(tasks) do
                if not v.filter or ev[1] == v.filter then
                    local ok,filter = coroutine.resume(v.coro)
                    if ok then v.filter = filter end
                    if ok and coroutine.status(v.coro) == "dead" then
                        tasks[k] = nil
                    elseif not ok and coroutine.status(v.coro) == "dead" then
                        run = false
                        printError("Error in background task: "..tostring(filter))
                    end
                end
            end
        end
    end

    function methods.set_block(tile,x,y,z)
        expect(1,tile,"string","table","nil")
        expect(2,x,"number")
        expect(3,y,"number")
        expect(4,z,"number")
        init_grid_point(x,y,z)
        grid[y][z][x] = tile
    end

    function methods.move_block(x,y,z,fx,fy,fz)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        expect(4,fx,"number")
        expect(5,fy,"number")
        expect(6,fz,"number")
        local tile = grid[y] and grid[y][z] and grid[y][z][x]
        if tile then
            grid[y][z][x] = nil
            init_grid_point(fx,fy,fz)
            grid[fy][fz][fx] = tile
        end
    end

    function methods.set_blocks(blocks)
        expect(1,blocks,"table")
        for k,v in pairs(blocks) do
            if not (type(v.x) == "number") then error("Error during isometrih.set_blocks: Block " ..k.." has invalid x position") end
            if not (type(v.y) == "number") then error("Error during isometrih.set_blocks: Block " ..k.." has invalid y position") end
            if not (type(v.z) == "number") then error("Error during isometrih.set_blocks: Block " ..k.." has invalid z position") end
            if not (type(v.tile) == "string" or type(v.tile) == "nil") then error("Error during isometrih.set_blocks: Block "..k.." is missing 'tile'") end
            init_grid_point(v.x,v.y,v.z)
            grid[v.y][v.z][v.x] = v.tile
        end
    end

    function methods.get_block(x,y,z)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        return grid[y] and grid[y][z] and grid[y][z][x]
    end

    function methods.get_tiles(filter)
        expect(1,filter,"function")
        local found = {}
        for y,layer in iterate_order(grid) do
            for z,row in iterate_order(layer) do
                for x,sprite_name in iterate_order(row) do
                    local sprite_name = row[x]
                    local sprites = {}
                    if type(sprite_name) == "string" then sprites = {sprite_name}
                    elseif type(sprite_name) == "table" then sprites = sprite_name end
                    for k,sprite in ipairs(sprites or {}) do
                        if filter(sprite,x,y,z) then
                            found[#found+1] = {x=x,y=y,z=z,sprite=sprite}
                        end
                    end
                end
            end
        end
        return found
    end

    function methods.get_tile_definitions()
        return methods.get_tiles(function() return true end)
    end

    function methods.get_bounds()
        local min_x,max_x = math.huge,-math.huge
        local min_y,max_y = grid.start or 1,grid.n
        local min_z,max_z = math.huge,-math.huge
        for y=grid.start or 1,grid.n do
            local layer = grid[y]
            local startz = (layer or {start=1}).start
            local endz = (layer or {n=0}).n
            min_z = math.min(min_z,startz)
            max_z = math.max(max_z,endz)
            for z=startz,endz do
                local row = layer[z]
                local startx = (row or {start=1}).start
                local endx = (row or {n=0}).n or 0
                min_x = math.min(min_x,startx)
                max_x = math.max(max_x,endx)
            end
        end
        return {
            {min_x,max_x},
            {min_y,max_y},
            {min_z,max_z}
        }
    end

    function methods.fill_blocks(tile,start_x,start_y,start_z,end_x,end_y,end_z)
        expect(1,tile,"string","table","nil")
        if start_x > end_x then start_x,end_x = end_x,start_x end
        if start_y > end_y then start_y,end_y = end_y,start_y end
        if start_z > end_z then start_z,end_z = end_z,start_z end
        for x=start_x,end_x do
            for y=start_y,end_y do
                for z=start_z,end_z do
                    init_grid_point(x,y,z)
                    grid[y][z][x] = tile
                end
            end
        end
    end

    function methods.replace_blocks(start_type,new_type)
        expect(1,start_type,"string")
        expect(1,new_type,"string")
        methods.get_tiles(function(sprite,x,y,z)
            if sprite == start_type then
                grid[y][z][x] = new_type
            end
        end)
    end

    function methods.reload_tiles()
        loaded_tiles = {}
        load_images()
    end

    function methods.get_loaded_tiles()
        return loaded_tiles
    end

    function methods.get_tile_cache()
        return tiles
    end

    function methods.remove_from_tile_cache(tile)
        expect(1,tile,"string")
        for k,v in pairs(tiles) do
            if v.tile_name == tile then
                tiles[k] = nil
            end
        end
    end

    function methods.load_tile(...)
        for k,v in pairs({...}) do
            table.insert(tiles,v)
        end
    end

    function methods.unload_tiles()
        loaded_tiles = {}
    end

    function methods.unload_tile(type)
        expect(1,type,"string")
        loaded_tiles[type] = nil
    end

    function methods.delete_tile(...)
        for k,v in pairs({...}) do
            tiles[v] = nil
        end
        load_images()
    end

    function methods.set_screen_offset_script(x,y,z,f)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        expect(4,f,"function")
        if not screen_offset_scripts[x] then screen_offset_scripts[x] = {} end
        if not screen_offset_scripts[x][y] then screen_offset_scripts[x][y] = {} end
        screen_offset_scripts[x][y][z] = f
    end

    function methods.del_screen_offset_script(x,y,z)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        if not screen_offset_scripts[x] then screen_offset_scripts[x] = {} end
        if not screen_offset_scripts[x][y] then screen_offset_scripts[x][y] = {} end
        screen_offset_scripts[x][y][z] = nil
    end

    function methods.del_screen_offset_scripts()
        screen_offset_scripts = {}
    end

    function methods.set_grid_offset_script(x,y,z,f)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        expect(4,f,"function")
        if not grid_offset_scripts[x] then grid_offset_scripts[x] = {} end
        if not grid_offset_scripts[x][y] then grid_offset_scripts[x][y] = {} end
        grid_offset_scripts[x][y][z] = f
    end

    function methods.del_grid_offset_script(x,y,z)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        if not grid_offset_scripts[x] then grid_offset_scripts[x] = {} end
        if not grid_offset_scripts[x][y] then grid_offset_scripts[x][y] = {} end
        grid_offset_scripts[x][y][z] = nil
    end

    function methods.del_tile_update_scripts()
        screen_offset_scripts = {}
    end

    function methods.set_tile_update_script(x,y,z,f)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        expect(4,f,"function")
        if not tile_update_scripts[x] then tile_update_scripts[x] = {} end
        if not tile_update_scripts[x][y] then tile_update_scripts[x][y] = {} end
        tile_update_scripts[x][y][z] = f
    end

    function methods.del_tile_update_script(x,y,z)
        expect(1,x,"number")
        expect(2,y,"number")
        expect(3,z,"number")
        if not tile_update_scripts[x] then tile_update_scripts[x] = {} end
        if not tile_update_scripts[x][y] then tile_update_scripts[x][y] = {} end
        tile_update_scripts[x][y][z] = nil
    end

    function methods.del_grid_offset_scripts()
        tile_update_scripts = {}
    end

    function methods.set_jhat(n)
        expect(1,n,"number")
        j = -n
    end

    function methods.set_ihat(n)
        expect(1,n,"number")
        i = n
    end

    function methods.set_compression_level(n)
        expect(1,n,"number")
        press_amount = n
    end

    function methods.set_screen_offset(x,y)
        expect(1,x,"number","nil")
        expect(2,y,"number","nil")
        if type(x) == "number" then screen_offset_x = x end
        if type(y) == "number" then screen_offset_y = y end
    end

    function methods.set_grid_offset(x,y,z)
        expect(1,x,"number","nil")
        expect(2,y,"number","nil")
        expect(3,z,"number","nil")
        if type(x) == "number" then grid_offset_x = x end
        if type(y) == "number" then grid_offset_y = y end
        if type(z) == "number" then grid_offset_z = z end
    end

    function methods.set_update_rate(n)
        expect(1,n,"number")
        update_rate = n
    end

    function methods.get_grid()
        return grid
    end

    function methods.clear_grid()
        grid = {}
    end

    function methods.schedule_task(f)
        expect(1,f,"function")
        tasks[{}] = {
            coro = coroutine.create(f)
        }
    end

    function methods.pause_render()
        render_enabled = false
    end

    function methods.resume_render()
        render_enabled = true
    end

    methods.start                 = methods.run
    methods.get_tile              = methods.get_block
    methods.set_tile              = methods.set_block
    methods.fill_tiles            = methods.fill_blocks
    methods.replace_tiles         = methods.replace_blocks
    methods.load_tiles            = methods.load_tile
    methods.get_block_definitions = methods.get_tile_definitions
    methods.set_tiles             = methods.set_blocks
    methods.move_tile             = methods.move_block
    methods.async                 = methods.schedule_task

    return setmetatable(data,{__index=methods})
end

return init