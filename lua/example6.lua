-- Example 6 - Generating Score
-- Author: Steven Yi <stevenyi@gmail.com>
-- 2013.10.28
-- for lua by:
-- Francesco Porta <francescoarmandoporta@gmail.com>
-- 2016

-- This example continues on from Example 5, rewriting the example using
-- a Class called Note. The note example has its tostring method implemented
-- to generate a well-formatted Csound SCO note.  
--
-- This example also shows how a list of notes could be used multiple times.
-- The first loop through we use the notes as-is, and during the second time
-- we generate the notes again with the same properties except we alter the 
-- fifth p-field up 4 semitones. 
--
-- Note: Altering a Notes values like this is alright for this example, but 
-- it is a destructive edit.  Real world code might make copies of Notes or 
-- alter the score generation to maintain the original values. 

require "luaCsnd6"

-- Convert MIDI Note Numbers to Csound PCH format
function midi2pch(num)
    return string.format("%d.%02d", 3 + (num / 12), num % 12)
end

local Note = {}

function Note:new(pfields)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.pfields = pfields
    return o
end

function Note:toString()
    local retVal = {}
    for i, v in ipairs(self.pfields) do
        if(i == 5) then
            retVal[#retVal+1] = midi2pch(v)
        else
            retVal[#retVal+1] = v
        end
    end
    return "i" .. table.concat(retVal, " ")
end

-- Our Orchestra for our project
local orc = [[
sr=44100
ksmps=32
nchnls=2
0dbfs=1

instr 1 
ipch = cps2pch(p5, 12)
kenv linsegr 0, .05, 1, .05, .7, .4, 0
aout vco2 p4 * kenv, ipch 
aout moogladder aout, 2000, 0.25
outs aout, aout
endin
]]

-- create an instance of Csound
local c = luaCsnd6.Csound()

-- Set option for Csound
c:SetOption("-odac")

-- Compile Orchestra from String
c:CompileOrc(orc)

--initialize a table to hold lists of values
local notes = {}

--populate that table
for i=0, 12 do
    notes[#notes+1] = Note:new{1, i * .25, .25, 0.5, math.random(60,75)}
end

-- now convert list of Note objects to string
local sco = ""
for _,n in pairs(notes) do
    -- this implicitly calls the tostring method on the Note Class
    sco = sco .. n:toString() .. "\n"
end

-- generate notes again transposed a Major 3rd up
for _,n in pairs(notes) do
    n.pfields[5] = n.pfields[5] + 4
    n.pfields[2] = n.pfields[2] + .125
    sco = sco .. n:toString() .. "\n"
end

print(sco)

-- Read in Score generated from notes 
c:ReadScore(sco)

-- When compiling from strings, this call is necessary before doing any performing
c:Start()

-- The following is our main performance loop. We will perform one block of sound at a time 
-- and continue to do so while it returns 0, which signifies to keep processing.  
while (c:PerformKsmps() == 0) do end

c:Stop()


