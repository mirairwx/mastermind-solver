#!/usr/bin/env luajit

local function printf(fmt, ...) io.write(string.format(fmt, ...)) end

math.randomseed(os.time()^5*os.clock())

local getopt = require"posix.unistd".getopt

local fopt={
	["h"] = function (optarg,optind)
		io.stderr:write(
			string.format(
				"Mastermind minimax solver ©2022 Eduardo Rhenius\n"
				.."Usage: %s [OPTION]...\n\n"
				.."  -h  display this help\n"
				.."  -p  pegs (4)\n"
				.."  -t  turns (5)\n\n",
				arg[0]
				)
			)
			os.exit(1)
		end,
	["p"] = function (optarg,optind)
		number_pegs = tonumber(optarg)
		end,
	
	["t"] = function (optarg,optind)
		number_rounds = tonumber(optarg)
		end,
	}

for r, optarg, optind in getopt(arg, "p:t:h") do
	last_index = optind
	if fopt[r](optarg, optind) then break end
end

codes = {}
codeset = {}
S = {}
score = {}

number_pegs = number_pegs or 4
number_rounds = number_rounds or 5
max_round = number_rounds+1

__PEGS_TABLE = {}
for i=1, number_pegs do __PEGS_TABLE[#__PEGS_TABLE+1] = 1 end
peg_number = table.concat(__PEGS_TABLE)

for i=peg_number, peg_number*6 do
	if string.match(i, "[07-9]") then goto continue end
	codes[i] = true
	S[i] = true
	score[i] = 0
	codeset[#codeset+1] = i
	::continue::
end

psymbol = {"r", "w", "."}

function first_gen()
	local second = (math.floor(number_pegs/2))
	local first = second + (number_pegs % 2)
	local number_table = {}
	for i=1, first do number_table[#number_table+1] = 1 end
	for i=1, second do number_table[#number_table+1] = 2 end
	return table.concat(number_table)
end

local function dissect_code(code)
	t = {}
	for digit in string.gmatch(code, "%d") do
		t[#t+1] = digit
	end
	return t
end

-- test
local test = codes[peg_number*6]
local test2 = codeset[7]
printf("code gen %s   codeset loop %d\n", test, test2)

local code_crack = codeset[math.random(#codeset)]
-- code_crack = 1122
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
	for i=1,number_pegs do 
		pattern[i] = psymbol[3] end
	for i=1,number_pegs do
		if cd[i] == dt[i] then
			pattern[i] = psymbol[1]
			cd[i], dt[i] = nil, nil
		end
	end
	for i=1,number_pegs do
		for j=1,number_pegs do
			if cd[i] == dt[j] and pattern[i] ~= psymbol[1] then
				pattern[i] = psymbol[2]
				cd[i], dt[j] = nil, nil
			end
		end
	end
	return pattern
end

function guess(code)
	count = count or 1
	local pattern = pegs_pattern(dissect_code(code), dissect_code(code_crack))
	
	table.sort(pattern)
	pattern = string.gsub(table.concat(pattern), "[.]", "")
	bullets = pattern; bullets = string.gsub(bullets, "r", "●"); bullets = string.gsub(bullets, "w", "○")
	printf("turn %d -> %d   %s\n", count, code, bullets)
	
	if pattern == string.rep("r", number_pegs) and count ~= max_round then
		return true, count, pattern
	elseif count >= max_round then
		return false, count, pattern
	else
		count = count + 1
		return false, count, pattern
	end
end

function solve()
	first_guess = first_gen()
	solved, tries, current_pattern = guess(first_guess)
	current_guess = first_guess
	-- solving loop
	for i=1,number_rounds do
		-- check for win
		if solved == true then
			return solved, tries
		elseif solved == false and count == max_round then printf("\asolved -> false\n") os.exit()
		else
		-- remove from S any code that would not give the same pattern
		for k, v in pairs(S) do
			local S_code_pattern = pegs_pattern(dissect_code(k), dissect_code(current_guess))
			table.sort(S_code_pattern)
   			S_code_pattern = string.gsub(table.concat(S_code_pattern), "[.]", "")
			if S_code_pattern ~= current_pattern then S[k] = nil end end
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
  	for i=peg_number, peg_number*6 do if string.match(i, "07-9]") then goto test
    		score[i] = 0 ::test:: end end
	end 	 -- end solving loop
end        	 -- end solve()
local solved, tries = solve()

-- confirmation
if solved == true then
  printf("solved -> %s   solved in %d\n", solved, tries)
end
