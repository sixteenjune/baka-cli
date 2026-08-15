
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local exec = require("lib.exec")

local M = {}

local function todos_path()
	local xdg = os.getenv("XDG_CONFIG_HOME")
	local config_dir
	if xdg and xdg ~= "" then
		config_dir = xdg .. "/baka"
	else
		config_dir = os.getenv("HOME") .. "/.config/baka"
	end
	return config_dir .. "/todos.txt"
end

local function load_todos()
	local path = todos_path()
	local todos = {}
	
	local f = io.open(path, "r")
	if not f then
		return todos
	end
	
	for line in f:lines() do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")  -- trim
		if line ~= "" then
			table.insert(todos, line)
		end
	end
	f:close()
	
	return todos
end

local function save_todos(todos)
	local path = todos_path()
	local dir = path:match("(.*/)")
	os.execute('mkdir -p "' .. dir .. '"')
	
	local f = io.open(path, "w")
	if not f then
		colors.error("couldn't write todos file at " .. path)
		os.exit(1)
	end
	
	for _, todo in ipairs(todos) do
		f:write(todo .. "\n")
	end
	f:close()
end

local function view_todos()
	local todos = load_todos()
	
	if #todos == 0 then
		colors.info("no todos yet -- add one with `baka todo add \"something\"`")
		return
	end
	
	format.heading("todos", icons.checkbox)
	for i, todo in ipairs(todos) do
		print(string.format("  %d) %s", i, todo))
	end
	print()
	colors.info(#todos .. " total")
end

local function add_todo(text)
	if not text or text == "" then
		colors.error("usage: baka todo add \"your todo text here\"")
		os.exit(1)
	end
	
	local todos = load_todos()
	for _, todo in ipairs(todos) do
		if todo == text then
			colors.warn("that todo already exists")
			return
		end
	end
	
	table.insert(todos, text)
	save_todos(todos)
	colors.success("added: " .. text)
end

local function list_todos()
	local todos = load_todos()
	
	if #todos == 0 then
		colors.info("no todos")
		return
	end
	
	for i, todo in ipairs(todos) do
		print(string.format("%d) %s", i, todo))
	end
end

local function remove_todo(text)
	if not text or text == "" then
		colors.error("usage: baka todo rm \"exact text match\"")
		os.exit(1)
	end
	
	local todos = load_todos()
	local found = false
	local remaining = {}
	
	for _, todo in ipairs(todos) do
		if todo == text then
			found = true
		else
			table.insert(remaining, todo)
		end
	end
	
	if not found then
		colors.warn("todo not found: " .. text)
		return
	end
	
	save_todos(remaining)
	colors.success("removed: " .. text)
end

local function clear_todos()
	save_todos({})
	colors.success("all todos cleared")
end

function M.run(arg)
	local subcommand = arg[2]
	if not subcommand or subcommand == "" then
		view_todos()
		return
	end
	
	if subcommand == "add" then
		add_todo(arg[3])
	elseif subcommand == "ls" or subcommand == "list" then
		list_todos()
	elseif subcommand == "rm" or subcommand == "remove" then
		remove_todo(arg[3])
	elseif subcommand == "clear" then
		clear_todos()
	else
		colors.error("unknown subcommand '" .. subcommand .. "'")
		colors.info("try: add, ls, rm, clear")
		os.exit(1)
	end
end

return M
