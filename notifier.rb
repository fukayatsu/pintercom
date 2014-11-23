#!/usr/bin/env ruby

require 'idobata_hook'
require 'pi_piper'
require 'json'
require 'faraday'
require 'dotenv'
# require 'pry'

Dotenv.load

# Process.daemon

class Notifier
  def initialize
    @idobata = IdobataHook::Client.new(ENV['IDOBATA_HOOK_URL'])
  end

  def watch_pin
    PiPiper.after pin: 24, goes: :down  do |pin|
      Thread.new do
        puts "[#{Time.now}] button pressed"

        `cd /home/pi/pintercom; raspistill -t 1 -o tmp/pic.jpg -w 1280 -h 800 -q 80`

        @idobata.send(ENV['IDOBATA_MESSAGE'], format: :text, image_path: 'tmp/pic.jpg')
      end
    end
  end

  def start
    `echo "24" > /sys/class/gpio/unexport`
    watch_pin
    `echo high > /sys/class/gpio/gpio24/direction` # pull-up

    puts "[#{Time.now}] start"
    PiPiper.wait
  end
end

Notifier.new.start

