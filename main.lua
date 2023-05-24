local sol_engine=require("sol.engine")
local sol_argparser=require("sol.argparser")

--[[ Globals ]]
local SolEngineMainInstance=sol_engine.Sol_NewEngine()
local SolEnginePathResources="./game/"

--[[ love.help() ]]
function love.help()
  os.exit(
    (function(lines) for _, line in ipairs(lines) do print(line) end return 0 end)(
      {
        ">> This is a list of commands you can use on the Sol Engine",
        "--root/-r:               defines the path for the game folder.",
        "--debug/-d:              shows additional information runtime.",
        "--help/-h:               shows this text and quit."
      }
    )
  )
end

--[[ love.load(args) ]]
function love.load(args)
  sol_argparser.Sol_UserArgumentsDecode(args, {
    --
    ["--debug"]={nargs=0, wrap=function() _G.dmsg_en=true end},
    ["-d"]="--debug",
    --
    ["--help"] ={nargs=0, wrap=function() love.help() end},
    ["-h"]="--help",
    --
    ["--root"] ={nargs=1, wrap=function(path) SolEnginePathResources=path end},
    ["-r"]="--root",
    --
    ["default"]=function(argument)
      dmsg("unknown argument \"%s\", ignoring...", argument)
    end,
  })
  --
  sol_engine.Sol_InitEngine(SolEngineMainInstance, SolEnginePathResources)
  --
  dmsg(">> running on lua: %s (jit? %s), love: %d.%d.%d [%s]", _VERSION, (_G["jit"] and "yes" or "no"), love.getVersion())
end

--[[ love.resize(new_width, new_height) ]]
function love.resize(new_width, new_height)
  sol_engine.Sol_NewResizeEventEngine(SolEngineMainInstance, new_width, new_height)
end

--[[ love.update(dt: decimal) ]]
function love.update(deltatime)
  sol_engine.Sol_TickEngine(SolEngineMainInstance)
end

--[[ love.keypressed() ]]
function love.keypressed(key)
  sol_engine.Sol_KeypressEventEngine(SolEngineMainInstance, key)
end

--[[ love.draw() ]]
function love.draw()
  sol_engine.Sol_DrawEngine(SolEngineMainInstance)
end