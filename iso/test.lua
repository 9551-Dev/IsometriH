local pixelbox = require("pixelbox")
local box = pixelbox.new(term.current())
term.clear()

local function make_filled_layer(type,n)
    local out = {n=n}
    for i=1,n do
        out[i] = {n=n}
        for i2=1,n do
            out[i][i2] = type
        end
    end
    return out
end

local grid = {
    n=10,
    {
        n=10,
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"leaves",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,"leaves","leaves","leaves",nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"leaves",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
    },
    {
        n=10,
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"leaves",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,"leaves","leaves","leaves",nil,nil,nil,nil,nil,nil},
        {n=10,"leaves","leaves","leaves","leaves","leaves",nil,nil,nil,nil,nil},
        {n=10,nil,"leaves","leaves","leaves",nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"leaves",nil,nil,nil,nil,nil,nil,nil},
    },
    {
        n=10,
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"leaves",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,"leaves","leaves","leaves",nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"leaves",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
    },
    {
        n=10,
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"wood",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
    },
    {
        n=10,
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"wood",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
    },
    {
        n=10,
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,"wood",nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
        {n=10,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
    },
    {
        n=10,
        {n=10,"sand","sand","sand","sand","sand","grass","grass","grass","grass","grass"},
        {n=10,"sand","water","water","water","sand","grass","grass","grass","grass","grass"},
        {n=10,"sand","water","water","water","sand","grass","grass","grass","grass","grass"},
        {n=10,"sand","water","water","sand","sand","grass","grass","grass","grass","grass"},
        {n=10,"sand","water","water","sand","grass","grass","grass","grass","grass","grass"},
        {n=10,"sand","sand","sand","sand","grass","grass","grass","grass","grass","grass"},
        {n=10,"grass","grass","grass","grass","grass","grass","grass","grass","grass","grass"},
        {n=10,"grass","grass","grass","grass","grass","grass","grass","grass","grass","grass"},
        {n=10,"grass","grass","grass","grass","grass","grass","grass","grass","grass","grass"},
        {n=10,"grass","grass","grass","grass","grass","grass","grass","grass","grass","grass"}
    },
    make_filled_layer("dirt",10),
    make_filled_layer("stone",10),
    make_filled_layer("cobble",10),
}

grid[9][2][10] = "lava"
grid[9][3][10] = "lava"
grid[9][4][10] = "lava"
grid[8][2][10] = nil
grid[8][3][10] = nil
grid[8][4][10] = nil
for x=2,9 do
    for y=2,9 do
        grid[9][y][x] = "lava"
        grid[8][y][x] = nil
    end
end

local i = 1
local j = -1
local press_amount = 0.5

local screen_width,screen_height = term.getSize()

screen_width = screen_width * 2
screen_height = screen_height * 3

local tiles = {
    {path="iso/blocks/grass.nfp",tile_name="grass"},
    {path="iso/blocks/dirt.nfp",tile_name="dirt"},
    {path="iso/blocks/stone.nfp",tile_name="stone"},
    {path="iso/blocks/cobblestone.nfp",tile_name="cobble"},
    {path="iso/blocks/leaves.nfp",tile_name="leaves"},
    {path="iso/blocks/sand.nfp",tile_name="sand"},
    {path="iso/blocks/water.nfp",tile_name="water"},
    {path="iso/blocks/wood.nfp",tile_name="wood"},
    {path="iso/blocks/lava.nfp",tile_name="lava"},
}

local loaded_tiles = {}
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

local function draw_image(image,x,y)
    for img_y=1,image.h do
        for img_x=1,image.w do
            local offset_x = math.ceil(x + img_x - 0.5)
            local offset_y = math.ceil(y + img_y - 0.5)
            local c = image.tex[img_y][img_x]
            if c then
                box:set_pixel(offset_x, offset_y, c, 1, true)
            end
        end
        box:push_updates()
        box:draw()
        sleep(0.005)
    end
end

local function draw()
    for y=grid.n,1,-1 do
        local layer = grid[y]
        for z=1,(layer or {n=0}).n or 0 do
            local row = layer[z]
            for x=1,(row or {n=0}).n or 0 do
                local sprite_name = row[x]
                local sprites = {}
                if type(sprite_name) == "string" then sprites = {sprite_name}
                elseif type(sprite_name) == "table" then sprites = sprite_name end
                for k,sprite in ipairs(sprites or {}) do
                    local sprite = loaded_tiles[sprite]
                    if sprite then
                        local screen_x = x*i + z*j
                        local screen_y = x*press_amount + z*press_amount + y - 1
                        local tex_x = screen_x*sprite.w/2 - sprite.w/2 + screen_width/2 - 1
                        local tex_y = screen_y*sprite.h/2
                        draw_image(sprite,tex_x,tex_y)
                    end
                end
            end
        end
    end
end

load_images()
while true do
    draw()
    box:push_updates()
    box:draw()
    box:clear(colors.black)
    sleep(5)
end

