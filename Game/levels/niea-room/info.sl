section info
    define  name, "Niea's Room"
end

section geometry
    define  enable_world_borders, yes
    define  bg_size, [20, 20]
    define  world_size, [20, 20]
    define  world_grid_tile_size, [128, 128]
end

section level
    define  spawn_layers,   ["background", "world_deco"]
    define  spawn_tiles,    ["X"]
end

section skybox
    section main
        define  method, "color"
        define  color, [0, 0, 0]
        define  textures, []
    end
    define  default, "main"
end