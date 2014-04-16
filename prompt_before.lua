local colors = {
    reset = "\x1b[0m",
    path = "\x1b[1;37;40m",
}

local function strip_gt()
	local prompt = clink.prompt.value
	if string.match(prompt, ">$") then
		prompt = string.sub(prompt, 1, #prompt - 1)
	end
	clink.prompt.value = colors.path..prompt..colors.reset
end

clink.prompt.register_filter(strip_gt, 40)
