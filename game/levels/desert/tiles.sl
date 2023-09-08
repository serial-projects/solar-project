section tiles
    section A
        define  name, "floor"
        define  size, [128, 128]
        define  position, [0, 0]
        define  collide, no
        define  zindex, 0
        # draw structure.
        section draw
            section recipes
                section main
                    define  draw_method, 4
                    define  textures, ["usualsand00"]
                    define  texture_index, 1
                    define  texture_timing, 0.1
                    define  texture_autoupdate, yes
                end-section
            end-section
            define  using_recipe, "main"
        end-section
    end-section
    section X
        define  name, "testingblock"
        define  size, [128, 128]
        define  position, [256, 256]
        define  collide, yes
        define  zindex, 2
        section draw
            section recipes
                section main
                    define  draw_method, 1
                    define  color, [255, 255, 255]
                end-section
            end-section
            define using_recipe, "main"
        end-section
        define  enable_interaction, yes
        section when_interacted
            define  name, "niea-room#main"
            define  source, "main"
            define  ticks_per_frame, 10
            define  begin_at, "player_interacted_with_in_desert"
        end-section
    end-section
end-section