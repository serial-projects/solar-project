# >> INFO:
section info
    define  name, "Desert"
end

# >> GEOMETRY:
section geometry
    define  enable_world_borders, yes
    define  world_size, [5, 5]
    define  world_grid_tile_size, [128, 128]
end

# >> LEVEL:
section level
    define  spawn_layers,   ["background"]
    define  spawn_tiles,    ["X"]
end

# >> SKYBOX:
section skybox
    section main
        define  method, "color"
        define  color, [0, 0, 0]
        define  textures, []
    end
    define  default, "main"
end