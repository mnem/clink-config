----------------------------------------------------------------------------
-- NOTE: This git prompt code is forked from:
--     https://github.com/djs/clink-gitprompt
----------------------------------------------------------------------------
--
-- Copyright (c) 2013 Dan Savilonis
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local colors = {
    reset = "\x1b[0m",
    clean = "\x1b[0;32;40m",
    dirty = "\x1b[0;31;1m",
}

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function file_exists(name)
    --http://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

local function directory_exists(path)
    return clink.is_dir(path)
end

local function file_contents(name)
    local file = io.open(name, "r")
    local data = file:read("*a")
    local rc = {file:close()}

    return data
end

local function git_repo_dirty()
    local file = io.popen("git status --porcelain 2>nul")
    local data = file:read("*a")
    local rc = {file:close()}

    return data ~= ""
end

local function git_dir()
    local file = io.popen("git rev-parse --git-dir 2>nul")
    local output = file:read('*all')
    local rc = {file:close()}
    return trim(output)
end

local function in_git_dir()
    local file = io.popen("git rev-parse --is-inside-git-dir 2>nul")
    local output = trim(file:read('*all'))
    local rc = {file:close()}
    if output == "true" then
        return true
    else
        return false
    end
end

local function in_bare_repo()
    local file = io.popen("git rev-parse --is-bare-repository 2>nul")
    local output = file:read('*all')
    local output = trim(file:read('*all'))
    local rc = {file:close()}
    if output == "true" then
        return true
    else
        return false
    end
end

local function inside_worktree()
    local file = io.popen("git rev-parse --is-inside-work-tree 2>nul")
    local output = trim(file:read('*all'))
    local rc = {file:close()}
    if output == "true" then
        return true
    else
        return false
    end
end

local function git_symbolic_ref(ref)
    local file = io.popen("git symbolic-ref " .. ref .. " 2>nul")
    local output = file:read('*all')
    local rc = {file:close()}
    return trim(output)
end

local function git_ps1()
    local pcmode = false
    local detached = false

    local g = git_dir()
    if not g then
        return ""
    end

    local r = ""
    local b = ""

    if file_exists(g .. "/rebase-merge/interactive") then
        r = "|REBASE-i"
        b = trim(file_contents(g .. "/rebase-merge/head-name"))
    elseif directory_exists(g .. "/rebase-merge") then
        r = "|REBASE-m"
        b = trim(file_contents(g .. "/rebase-merge/head-name"))
    else
        if directory_exists(g .. "/rebase-apply") then
            if file_exists(g .. "/rebase-apply/rebasing") then
                r = "|REBASE"
            elseif file_exists(g .. "/rebase-apply/applying") then
                r = "|AM"
            else
                r = "|AM/REBASE"
            end
        elseif file_exists(g .. "/MERGE_HEAD") then
            r = "|MERGING"
        elseif file_exists(g .. "/CHERRY_PICK_HEAD") then
            r = "|CHERRY-PICKING"
        elseif file_exists(g .. "/BISECT_LOG") then
            r = "|BISECTING"
        end

        b = git_symbolic_ref("HEAD")
        if not b then
            detached = true
            b = "detached"
        end
    end

    local w = ""
    local i = ""
    local s = ""
    local u = ""
    local c = ""
    local p = ""

    if in_git_dir() then
        if in_bare_repo() then
            c = "BARE:"
        else
            b = "GIT_DIR!"
        end
    elseif inside_worktree() then
        -- nada
    end

    local f = w..i..s..u

    b = string.gsub(b, "^refs/heads/", "")
    local prompt = c..b..f..r..p
    return prompt
end

local function git_prompt_filter()
    ps1 = git_ps1()
    if ps1 ~= "" then
        if git_repo_dirty() then
            ps1 = colors.dirty..ps1..colors.reset
        else
            ps1 = colors.clean..ps1..colors.reset
        end

        git_prompt = clink.prompt.value .. " (" .. ps1 .. ") "
        clink.prompt.value = git_prompt
    end

    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)
