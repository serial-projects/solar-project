# >> INFO:
section info
    define  name, "Desert"
end-section

# >> GEOMETRY:
section geometry
    define  enable_world_borders, yes
    define  bg_size, [5, 5]
    define  bg_tile_size, [128, 128]
end-section

# >> LEVEL:
section level
    define  spawn_layers,   ["background"]
    define  spawn_tiles,    ["X"]
end-section

# >> SKYBOX:
section skybox
    section main
        define  method, "color"
        define  color, [0, 0, 0]
        define  textures, []
    end-section
    define  default, "main"
end-section