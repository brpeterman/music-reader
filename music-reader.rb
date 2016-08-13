#!/usr/bin/env ruby

# Utility to read the Now Playing info from Google Play Music Desktop Player
# and write it to a text file for OBS to read.

require 'websocket-client-simple'
require 'json'

SERVER_URI = "ws://localhost:5672"
DIR_PATH = 'L:\Services\music-reader'
FILE_NAME = "now-playing.txt"

class MusicReader
  def initialize(uri, output_file)
    @uri = uri
    @run = true
    @playing = false
    @song = {}
    @filename = output_file
  end
  
  def run(block = true)
    @ws = WebSocket::Client::Simple.connect @uri
    setup_handlers
    if block then
      sleep 1 until !@run
    end
  end
  
  def disconnect
    @run = false
    write_text ""
  end

  def handle_playState(playing)
    @playing = playing
    if !playing then
      $stderr.puts "Clearing song"
      write_text ""
    else
      handle_song @song
    end
  end

  def handle_song(song_data)
    @song = song_data
    if @playing then
      song_string = build_song_string(song_data)
      if song_string
        $stderr.puts "Updated song to #{song_string}"
        write_text song_string
      end
    end
  end
  
  private
  
  def setup_handlers
    reader = self
    @ws.on :message do |msg|
      data = JSON.parse msg.data
      channel = data["channel"]
      payload = data["payload"]
      case channel
        when "playState"
          reader.handle_playState payload
        when "state" # There's a bug in the API where both "playState" and "state" are the same event
          reader.handle_playState payload
        when "track"
          reader.handle_song payload
      end
    end
    
    @ws.on :error do |e|
      $stderr.puts "Error: #{e.inspect}"
    end
  end

  def build_song_string(song_data)
    title = song_data["title"]
    artist = song_data["artist"]
    if title && artist then
      "\u25BA #{title} by #{artist}"
    end
  end

  def write_text(text_data)
    File.open(@filename, "w:UTF-8") do |file|
      file.print text_data
      sleep 1 # hold the file for a moment
    end
  end
end

trap "SIGINT" do
  $reader.disconnect
end

$reader = MusicReader.new SERVER_URI, "#{DIR_PATH}\\#{FILE_NAME}"
$reader.run
