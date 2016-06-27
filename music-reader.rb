#!/usr/bin/env ruby

# Utility to read the Now Playing info from Google Play Music Desktop Player
# and write it to a text file for OBS to read.

require 'websocket-client-simple'
require 'json'

SERVER_URI = "ws://localhost:5672"
DIR_PATH = 'L:\Services\music-reader'
FILE_NAME = "now-playing.txt"

$run = true

$ws = WebSocket::Client::Simple.connect SERVER_URI

$ws.on :message do |msg|
  data = JSON.parse msg.data
  channel = data["channel"]
  payload = data["payload"]
  case channel
    when "playState"
      handle_playState payload
    when "song"
      handle_song payload
  end
end

def handle_playState(playing)
  if !playing then
    write_text ""
  end
end

def handle_song(song_data)
  song_string = build_song_string(song_data)
  $stderr.puts "Updated song to #{song_string}"
  write_text song_string
end

def build_song_string(song_data)
  title = song_data["title"]
  artist = song_data["artist"]
  "Now Playing: #{title} by #{artist}"
end

def write_text(text_data)
  File.open("#{DIR_PATH}\\#{FILE_NAME}", "w") do |file|
    file.print text_data
  end
end

trap "SIGINT" do
  $run = false
  write_text ""
end

loop while $run