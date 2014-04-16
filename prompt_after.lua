local function add_gt()
	local prompt = clink.prompt.value
	prompt = prompt.."\n> "
	clink.prompt.value = prompt
end

clink.prompt.register_filter(add_gt, 100)
