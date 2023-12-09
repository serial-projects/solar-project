## section "tiles" ##
# >> Tiles are the fundamental building blocks on the Sol Engine.
section tiles
    section A
        define  name, "floor"
        define  size, [64, 64]
        define  position, [0, 0]
        define  collide, no
        define  zindex, -1

        # draw structure.
        section draw
            section recipes
                section main
                    define  draw_method, 4
                    define  textures, ["usualgrass00"]
                    define  texture_index, 1
                    define  texture_timing, 0.1
                    define  texture_autoupdate, yes
                end
            end
            define  using_recipe, "main"
        end
    end
    section X
        define  name, "testingblock"
        define  size, [64, 64]
        define  position, [500, 500]
        define  collide, yes
        define  zindex, 0
        section draw
            section recipes
                section main
                    define  draw_method, 1
                    define  color, [255, 255, 255]
                end
            end
            define using_recipe, "main"
        end
        define  enable_interaction, yes
        section when_interacted
            define  name, "niea-room#main"
            define  source, "main"
            define  ticks_per_frame, 10
            define  begin_at, "player_interacted_with"
        end
    end
    section F
        define  name, "largetile"
        define  size, [64, 64]
        define  position, [300, 200]
        define  collide, no
        define  should_draw, yes
        define  zindex, 0
        define  enable_interaction, no

        # draw structure
        section draw
            section recipes
                section main
                    define  draw_method, 3
                    define  textures, [
                        "usualflower00:frame01",
                        "usualflower00:frame02",
                        "usualflower00:frame03",
                        "usualflower00:frame04"
                    ]
                    define  texture_timing, 0.2
                    define  texture_index, 1
                    define  texture_autoupdate, yes
                end
            end
            define  using_recipe, "main"
        end
    end
end