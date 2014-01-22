#!/usr/bin/env ruby

require 'hipchat'
require 'pi_piper'
require 'json'
require 'faraday'
require 'dotenv'
#require 'pry'

Dotenv.load

# Process.daemon

class Notifier
  def initialize
    @hipchat = HipChat::Client.new(ENV['HIPTCHAT_API_TOKEN'])
    @http    = http
    @led     = PiPiper::Pin.new pin: 17, direction: :out
    @buzzer  = PiPiper::Pin.new pin: 4,   direction: :out
  end

  def http
    Faraday.new(url: ENV['HEROCKER_URL']) do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter :net_http 
    end
  end

  def beep(sec)
      @buzzer.on
      sleep sec
      @buzzer.off
  end

  def watch_pin
    PiPiper.after pin: 24, goes: :down  do |pin|
      Thread.new do
        @led.on; beep(0.1); @led.off
        puts "[#{Time.now}] button pressed"

        `cd /home/pi/pintercom; raspistill -t 1 -o tmp/pic.jpg -w 1280 -h 800 -q 80`

        beep(0.1); sleep 0.1; beep(0.1)

        @hipchat['entrance'].send('pintercom', "@here Someone has come!", message_format: 'text')
        image_url = upload('tmp/pic.jpg')
        @hipchat['entrance'].send('pintercom', image_url, message_format: 'text')

        @led.on; sleep(0.1); @led.off
      end
    end
    `echo high > /sys/class/gpio/gpio24/direction` # pull-up
  end

  def start
    watch_pin
    puts "[#{Time.now}] start"
    beep(0.1)
    PiPiper.wait
  end

  def upload(image_file)
    payload = {
      file: Faraday::UploadIO.new(image_file, 'image/jpeg'),
      upload_token: ENV['HEROCKER_UPLOAD_TOKEN'],
    }
    res = @http.post '/images.json', payload

    image_url = JSON.parse(res.body)["image_url"]

  rescue => e
    p e.message
    p "file upload error"
  end
end

Notifier.new.start

