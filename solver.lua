#!/usr/bin/env luajit

function printf (fmt, ...)
	return io.write(string.format(fmt, ...))
end

math.randomseed(os.time()*5)

codes = {}
codeset = {}
S = {}
score = {}
for i=1111, 6666 do
	if string.match(i, "[07-9]") then goto continue end
	codes[i] = true
	S[i] = true
	score[i] = 0
	codeset[#codeset+1] = i
	::continue::
end

psymbol = {"r", "w", "."}

local function dissect_code(code)
	t = {}
	for digit in string.gmatch(code, "%d") do
		t[#t+1] = digit
	end
	return t
end

-- test
local test = codes[6666]
local test2 = codeset[7]
printf("code gen %s   codeset loop %d\n", test, test2)

local code_crack = codeset[math.random(#codeset)]
-- code_crack = 1122
-- code_crack = 1222
-- code_crack = 3632

printf("decode -> %s\n", code_crack)

local function codes_copy(n, t)
	local n = {}
	for k, v in ipairs(t) do
		n[k] = v
	end
	return n
end

local function pegs_pattern(code_dsd, decode_table)
	local pattern = {}
	local cd = codes_copy(cd, code_dsd)
	local dt = codes_copy(dt, decode_table)
	for i=1,4 do 
		pattern[i] = psymbol[3] end
	for i=1,4 do
		if cd[i] == dt[i] then
			pattern[i] = psymbol[1]
			cd[i], dt[i] = nil, nil
		end
	end
	for i=1,4 do
		for j=1,4 do
			if cd[i] == dt[j] and pattern[i] ~= psymbol[1] then
				pattern[i] = psymbol[2]
				cd[i], dt[j] = nil, nil
			end
		end
	end
  -- pattern = string.gsub(table.concat(pattern), "[.]", "")
	return pattern
end

function cmp_pattern(p1, p2)
  local c1, c2 = p1, p2
  local c1_red_hits, c1_white_hits = 0, 0
  local c2_red_hits, c2_white_hits = 0, 0
  for r in string.gmatch(c1, "r") do c1_red_hits = c1_red_hits + 1 end
  for w in string.gmatch(c1, "w") do c1_white_hits = c1_white_hits + 1 end
  for r in string.gmatch(c2, "r") do c2_red_hits = c2_red_hits + 1 end
  for w in string.gmatch(c2, "w") do c2_white_hits = c2_white_hits + 1 end
  if (c1_red_hits == c2_red_hits) and (c1_white_hits == c2_white_hits) then return true else return false end
end

function guess(code)
	count = count or 1
	local code_dsd = dissect_code(code)
	local decode_table = dissect_code(code_crack)
	
	local pattern = pegs_pattern(code_dsd, decode_table)
	table.sort(pattern)
	pattern = string.gsub(table.concat(pattern), "[.]", "")
	bullets = pattern; bullets = string.gsub(bullets, "r", "●"); bullets = string.gsub(bullets, "w", "○")
	printf("turn %d -> %d   %s\n", count, code, bullets)
	
	if pattern == "rrrr" and count ~= 6 then
		return true, count, pattern
	elseif count >= 6 then
		return false, count, pattern
	else
		count = count + 1
		return false, count, pattern
	end
end

function solve()
	solved, tries, current_pattern = guess(1122)
	current_guess = 1122
	-- solving loop
	for i=1,5 do
		-- check for win
		if solved == true then
			return solved, tries
		else
		-- remove from S any code that would not give the same pattern
		for k, v in pairs(S) do
			local S_code_pattern = pegs_pattern(dissect_code(k), dissect_code(current_guess))
      S_code_pattern = string.gsub(table.concat(S_code_pattern), "[.]", "")
      if cmp_pattern(S_code_pattern, current_pattern) == false then S[k] = nil end
		end
		-- score each guess
		for k, v in pairs(codes) do
			local test_guess = k
      local test_table = {}
			for k, v in pairs(S) do
				local s_pattern = pegs_pattern(dissect_code(k), dissect_code(test_guess))
        table.sort(s_pattern)
        s_pattern = string.gsub(table.concat(s_pattern), "[.]", "")
        test_table[s_pattern] = (test_table[s_pattern] or 0) + 1
			end
      local index_test = {}
      for k in pairs(test_table) do index_test[#index_test+1] = k end 
      table.sort(index_test, function (c1, c2)
          return test_table[c1] > test_table[c2] or
          test_table[c1] == test_table[c2] and c1 > c2 end)
      score[test_guess] = test_table[index_test[1]]
		end
	end
  local score_list = {}
  for k in pairs(score) do
    score_list[#score_list + 1] = k
  end
	table.sort(score_list, function (c1, c2)
      return score[c1] < score[c2] or
      score[c1] == score[c2] and c1 < c2
    end)
  __TEST_TABLE = {}
  for k, v in pairs(S) do if score[score_list[1]] == score[k] then __TEST_TABLE[#__TEST_TABLE+1] = k end end
  table.sort(__TEST_TABLE)
  current_guess = __TEST_TABLE[1] or score_list[1]
  solved, tries, current_pattern = guess(current_guess)
  -- score regen
  for i=1111, 6666 do if string.match(i, "07-9]") then goto test
    score[i] = 0 ::test:: end end
	end 	 -- end solving loop
end        	 -- end solve()
local solved, tries = solve()

-- confirmation
if solved == true then
  printf("solved -> %s   solved in %d\n", solved, tries)
elseif solved == false and count == 6 then
  printf("solved -> %s   solving failed!\n", solved)
end
