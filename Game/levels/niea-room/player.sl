## section "player"
section player
    section  spawn
        define  use_tile_alignment, yes
        define  xpos, 10
        define  ypos, 10
    end
    section draw
        section recipes
            section 1
                define  draw_method, 3
                define  texture_autoupdate, no
                define  textures, ["playerwalkup:frame01","playerwalkup:frame02","playerwalkup:frame03","playerwalkup:frame04"]
            end
            section 2
                define  draw_method, 3
                define  texture_autoupdate, no
                define  textures, ["playerwalkdown:frame01","playerwalkdown:frame02","playerwalkdown:frame03","playerwalkdown:frame04"]
            end
            section 3
                define  draw_method, 3
                define  texture_autoupdate, no
                define  textures, ["playerwalkleft:frame01","playerwalkleft:frame02","playerwalkleft:frame03","playerwalkleft:frame04"]
            end
            section 4
                define  draw_method, 3
                define  texture_autoupdate, no
                define  textures, ["playerwalkright:frame01","playerwalkright:frame02","playerwalkright:frame03","playerwalkright:frame04"]
            end
        end
        define  counter, 0
        define  max_counter, 5
    end
    define  using_recipe, 1
    define  size, [128, 128]
end