require 'hipchat'
require 'pi_piper'
require 'nokogiri'
require 'faraday'
require 'dotenv'
#require 'pry'

Dotenv.load

class Notifier
  def initialize
    @hipchat = HipChat::Client.new(ENV['HIPTCHAT_API_TOKEN'])
    @http    = http
  end

  def http
    Faraday.new(url: "https://#{ENV['HIPCHAT_HOST']}") do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter :net_http 
    end
  end

  def watch_pin
    @notifier = self
    PiPiper.after pin: 24, goes: :down  do |pin|
      puts "[#{Time.now}] button pressed"
      @hipchat['entrance'].send('pintercom', "@here Someone has come!", message_format: 'text')

      `cd /home/pi/pintercom; raspistill -t 1 -o tmp/pic.jpg`
      image_url = upload('tmp/pic.jpg')
      @hipchat['entrance'].send('pintercom', image_url, message_format: 'text')
    end
    `echo high > /sys/class/gpio/gpio24/direction` # pull-up
  end

  def start
    watch_pin
    puts "[#{Time.now}] start"
    PiPiper.wait
  end

  def upload(image_file)
    payload = {
      user_id:  ENV['HIPCHAT_USER_ID'],
      group_id: ENV['HIPCHAT_GROUP_ID'],
      desc:     "taken at #{Time.now}",
      jid:      ENV['HIPCHAT_JID'],
      token:    ENV['HIPCHAT_CHAT_TOKEN'],
      Filedata: Faraday::UploadIO.new(image_file, 'image/jpeg'),
    }
    res = @http.post '/api/upload_file', payload

    xml      = Nokogiri.parse(res.body)
    filename = xml.xpath('response/filename').text
    bucket   = xml.xpath('response/bucket').text
    url      = "https://s3.amazonaws.com/#{bucket}/#{filename}"
  rescue => e
    "file upload error"
  end
end

Notifier.new.start

