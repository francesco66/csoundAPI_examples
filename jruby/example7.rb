# Example 7 - Communicating continuous values with Csound's Channel System
# Author: Steven Yi <stevenyi@gmail.com>
# 2013.10.28
#
# This example introduces using Csound's Channel System to communicate 
# continuous control data (k-rate) from a host program to Csound. The 
# first thing to note is the RandomLine class. It takes in a base value
# and a range in which to vary randomly.  The reset functions calculates
# a new random target value (self.end), a random duration in which to 
# run (self.dur, expressed as # of audio blocks to last in duration), and
# calculates the increment value to apply to the current value per audio-block.
# When the target is met, the Randomline will reset itself to a new target
# value and duration.
# 
# In this example, we use two RandomLine objects, one for amplitude and 
# another for frequency.  We start a Csound instrument instance that reads
# from two channels using the chnget opcode. In turn, we update the values
# to the channel from the host program.  In this case, because we want to 
# keep our values generating in sync with the audio engine, we use a 
# while-loop instead of a CsoundPerformanceThread. To update the channel,
# we call the SetChannel method on the Csound object, passing a channel name
# and value.  Note: The getValue method on the RandomLine not only gets
# us the current value, but also advances the internal state by the increment
# and by decrementing the duration.

require 'csnd6'
import 'csnd6.Csound'

class RandomLine
  def initialize(base, range)
    @curVal = 0.0
    reset
    @base = base
    @range = range
  end

  def reset
    @dur = rand(256..512) 
    @last = rand
    @increment = (@last - @curVal) / @dur
  end

  def getValue
    @dur -= 1
    @reset if @dur < 0
    tmp = @curVal
    @curVal += @increment
    @base + (@range * tmp)
  end
end

# Our Orchestra for our project
# using a HEREDOC allows us to embed double quotes
orc = <<ORC
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
ORC

c = Csound.new        # create an instance of Csound
c.SetOption("-odac")  # Set option for Csound
c.SetOption("-m7")    # Set option for Csound
c.CompileOrc(orc)     # Compile Orchestra from String

sco = "i1 0 60\n"

c.ReadScore(sco)      # Read in Score generated from notes 
c.Start               # When compiling from strings, this call is necessary before doing any performing

amp = RandomLine.new(0.4, 0.2)  # create RandomLine for use with Amplitude
freq = RandomLine.new(400, 80)  # create RandomLine for use with Frequency 
#puts amp.getValue
#puts freq.getValue

# Initialize channel values before running Csound
c.SetChannel("amp", amp.getValue)
c.SetChannel("freq", freq.getValue)

# The following is our main performance loop. We will perform one block of sound at a time 
# and continue to do so while it returns 0, which signifies to keep processing.  

while c.PerformKsmps == 0 do
  c.SetChannel("amp", amp.getValue)   # update channel value 
  c.SetChannel("freq", freq.getValue) # update channel value
end

c.Stop
c.Cleanup






