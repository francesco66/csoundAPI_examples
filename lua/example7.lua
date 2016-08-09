-- Example 7 - Communicating continuous values with Csound's Channel System
-- Author: Steven Yi <stevenyi@gmail.com>
-- 2013.10.28
-- for lua by:
-- Francesco Porta <francescoarmandoporta@gmail.com>
-- 2016

-- This example introduces using Csound's Channel System to communicate 
-- continuous control data (k-rate) from a host program to Csound. The 
-- first thing to note is the RandomLine class. It takes in a base value
-- and a range in which to vary randomly.  The reset functions calculates
-- a new random target value (self.end), a random duration in which to 
-- run (self.dur, expressed as -- of audio blocks to last in duration), and
-- calculates the increment value to apply to the current value per audio-block.
-- When the target is met, the Randomline will reset itself to a new target
-- value and duration.
-- 
-- In this example, we use two RandomLine objects, one for amplitude and 
-- another for frequency.  We start a Csound instrument instance that reads
-- from two channels using the chnget opcode. In turn, we update the values
-- to the channel from the host program.  In this case, because we want to 
-- keep our values generating in sync with the audio engine, we use a 
-- while-loop instead of a CsoundPerformanceThread. To update the channel,
-- we call the SetChannel method on the Csound object, passing a channel name
-- and value.  Note: The getValue method on the RandomLine not only gets
-- us the current value, but also advances the internal state by the increment
-- and by decrementing the duration.

require "luaCsnd6"


local RandomLine = {}

function RandomLine:new(base, range)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.curVal = 0.0
    o:reset()
    o.base = base
    o.range = range
    return o
end

function RandomLine:reset()
    self.dur = math.random(256,512)
    self.End = math.random()
    self.increment = (self.End - self.curVal) / self.dur
end

function RandomLine:getValue()
    self.dur = self.dur - 1
    if(self.dur < 0) then
        self:reset()
    end
    retVal = self.curVal
    self.curVal = self.curVal + self.increment
    return self.base + (self.range * retVal)
end

-- Our Orchestra for our project
local orc = [[
sr=44100
ksmps=32
nchnls=2
0dbfs=1

instr 1 
kamp chnget "amp"
kfreq chnget "freq"
printk 0.5, kamp
printk 0.5, kfreq
aout vco2 kamp, kfreq
aout moogladder aout, 2000, 0.25
outs aout, aout
endin
]]

-- create an instance of Csound
local c = luaCsnd6.Csound()
-- Set option for Csound
c:SetOption("-odac")
-- Set option for Csound
c:SetOption("-m7")
-- Compile Orchestra from String
c:CompileOrc(orc)

local sco = "i1 0 60\n"

-- Read in Score generated from notes 
c:ReadScore(sco)
-- When compiling from strings, this call is necessary before doing any performing
c:Start()

-- The following is our main performance loop. We will perform one block of sound at a time 
-- and continue to do so while it returns 0, which signifies to keep processing.  

-- create RandomLine for use with Amplitude
local amp = RandomLine:new(.4, .2)
-- create RandomLine for use with Frequency
local freq = RandomLine:new(400, 80)

-- Initialize channel value before running Csound
c:SetChannel("amp", amp:getValue())
-- Initialize channel value before running Csound
c:SetChannel("freq", freq:getValue())

--print(amp:getValue())
--print(freq:getValue())

while (c:PerformKsmps() == 0) do
    -- update channel value
    c:SetChannel("amp", amp:getValue())
    -- update channel value
    c:SetChannel("freq", freq:getValue())
end

c:Stop()


