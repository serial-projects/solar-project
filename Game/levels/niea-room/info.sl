section info
    define  name, "Niea's Room"
end-section

section geometry
    define  enable_world_borders, yes
    define  bg_size, [20, 20]
    define  bg_tile_size, [128, 128]
end-section

section level
    define  spawn_layers,   ["background", "world_deco"]
    define  spawn_tiles,    ["X"]
end-section

section skybox
    section main
        define  method, "color"
        define  color, [0, 0, 0]
        define  textures, []
    end-section
    define  default, "main"
end-section