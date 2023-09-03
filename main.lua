-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SolarEngine = require("Solar.Engine")
local SolarArguments = require("Solar.System.Arguments")

--[[ Globals ]]
local SolEngineMainInstance=SolarEngine.Sol_NewEngine()
local SolEnginePathResources="game/"

--[[ love.help() ]]
function love.help()
  -- TODO: on the future, implement translation to this.
  os.exit((function(lines) for _, line in ipairs(lines) do print(line) end return 0 end)(
      {
        ">> This is a list of commands you can use on the Sol Engine",
        "--root/-r <path>:        defines the path for the game folder.",
        "--log/-l <file>:         set the output for additional information.",
        "--debug/-d:              shows additional information runtime.",
        "--help/-h:               shows this text and quit.",
        "--version/-v:            shows the version of the engine."
      }
    )
  )
end

--[[ love.load(args) ]]
function love.load(args)
  SolarArguments.Sol_UserArgumentsDecode(args, {
    --
    ["--debug"]={nargs=0, wrap=function()
      setdebug(true)
    end}, ["-d"]="--debug",
    ["--log"]={nargs=1, wrap=function(path)
      logfileset(path)
    end}, ["-l"]="--log",
    --
    ["--help"] ={nargs=0, wrap=function()
      love.help()
    end}, ["-h"]="--help",
    --
    ["--root"] ={nargs=1, wrap=function(path)
      SolEnginePathResources=path
    end}, ["-r"]="--root",
    --
    ["--version"]={nargs=0, wrap=function(path)
      local _defaults=require("sol.defaults")
      print(string.format("Sol Engine Version: \"%s\" by Pipes Studios", _defaults.SOL_VERSION))
    end}, ["-v"]="--version",
    --
    ["default"]=function(argument)
      dmsg("unknown argument \"%s\", ignoring...", argument)
    end,
  })
  --
  SolarEngine.Sol_InitEngine(SolEngineMainInstance, SolEnginePathResources)
  --
  msg(">> running on lua: %s (jit? %s), love: \"%d.%d.%d\" [%s]", _VERSION, (_G["jit"] and "yes" or "no"), love.getVersion())
end

--[[ love.resize(new_width, new_height) ]]
function love.resize(new_width, new_height)
  SolarEngine.Sol_NewResizeEventEngine(SolEngineMainInstance, new_width, new_height)
end

--[[ love.update(dt: decimal) ]]
function love.update(deltatime)
  SolarEngine.Sol_TickEngine(SolEngineMainInstance)
end

--[[ love.keypressed() ]]
function love.keypressed(key)
  if key == 'l' then qcrash(-1, "bruh") end
  SolarEngine.Sol_KeypressEventEngine(SolEngineMainInstance, key)
end

--[[ love.draw() ]]
function love.draw()
  SolarEngine.Sol_DrawEngine(SolEngineMainInstance)
end