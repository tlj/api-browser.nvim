local files = require("api-browser.files")
local Job = require("plenary.job")
local utils = require("api-browser.utils")

local M = {
	options = {
		command = "curl",
		formatters = {
			["application/json"] = { "jq", "." },
			["application/xml"] = { "xmllint", "-format" },
		},
	},
}

M.fetch_async = function(endpoint, callback)
	local headers_file = os.tmpname()
	local body_file = os.tmpname()

	local args = { "-D", headers_file, "-o", body_file, "-s" }

	for h, v in pairs(endpoint.headers or {}) do
		table.insert(args, "-H")
		table.insert(args, h .. ": " .. v)
	end

	local fetchUrl = endpoint.base_url .. endpoint.url
	table.insert(args, fetchUrl)

	local stdout = {}
	local stderr = {}

	Job:new({
		command = M.options.command,
		args = args,
		on_stdout = function(_, line)
			table.insert(stdout, line)
		end,
		on_stderr = function(_, line)
			table.insert(stderr, line)
		end,
		on_exit = vim.schedule_wrap(function(_, exit_code)
			local headers = M.parse_headers(headers_file)
			local output = M.format_output(endpoint, body_file)

			local result = {
				stdout = stdout,
				stderr = stderr,
				headers = headers.headers,
				status_code = headers.status,
				output = output,
				exit_code = exit_code,
			}

			callback(result)
		end),
	}):start()
end

local function get_os_command_output(cmd, cwd)
	local command = table.remove(cmd, 1)
	local stderr = {}
	local stdout, ret = Job:new({
		command = command,
		args = cmd,
		cwd = cwd,
		on_stderr = function(_, data)
			table.insert(stderr, data)
		end,
	}):sync(60000)
	return stdout, ret, stderr
end

M.format_output = function(endpoint, body_file, opts)
	opts = opts or {}

	local original_body = files.lines_from(body_file)

	for ct, cmd in pairs(M.options.formatters) do
		if utils.content_type(endpoint) == ct then
			local newcmd = vim.deepcopy(cmd)
			table.insert(newcmd, body_file)
			local body, ret, err = get_os_command_output(newcmd, opts.cwd)
			if ret ~= 0 then
				vim.notify("Error " .. ret .. " while calling " .. cmd[1] .. " to format output: " .. err[1])
				return original_body
			end
			return body
		end
	end

	vim.notify("No matching formatter found for " .. endpoint.url .. " content-type " .. utils.content_type(endpoint))
	return original_body
end

function M.parse_headers(headers_file)
	local result = {
		status = 0,
		headers = {},
	}
	local header_lines = files.lines_from(headers_file)
	for _, v in pairs(header_lines) do
		v = v:gsub("\r\n", "\n")

		local status = string.match(v, "^HTTP/.- (%d+) ")
		if status ~= nil then
			result.status = tonumber(status)
		end

		local name, value = string.match(v, "(.-):%s*(.-)$")
		if name ~= nil and value ~= nil then
			result.headers[name] = value
		end
	end
	return result
end

return M
