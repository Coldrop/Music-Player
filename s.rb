require 'rubygems'
require 'gosu'

module ZOrder
  BACKGROUND, ALBUM, TRACK, UI = *0..3
end

class Album
  attr_accessor :title, :artist, :artwork, :tracks

  def initialize(title, artist, artwork, tracks)
    @title = title
    @artist = artist
    @artwork = artwork
    @tracks = tracks
  end
end

class Track
  attr_accessor :name, :location

  def initialize(name, location)
    @name = name
    @location = location
  end
end

class MusicPlayer < Gosu::Window
  SCREEN_WIDTH = 800
  SCREEN_HEIGHT = 600

  def initialize
    super(SCREEN_WIDTH, SCREEN_HEIGHT)
    self.caption = "Music Player"
    @font = Gosu::Font.new(24)
    @albums = read_albums
    @selected_album = nil
    @selected_track = nil
    @song = nil
    @in_album_selection = true
    @now_playing = nil
  end

  def read_albums
    albums = []

    File.open("input.txt", "r") do |file|
      num_albums = file.gets.chomp.to_i

      num_albums.times do
        title = file.gets.chomp
        artist = file.gets.chomp
        artwork_path = file.gets.chomp
        tracks_count = file.gets.chomp.to_i
        tracks = []

        tracks_count.times do
          track_name = file.gets.chomp
          track_location = file.gets.chomp
          tracks << Track.new(track_name, track_location)
        end

        artwork = Gosu::Image.new(artwork_path)
        albums << Album.new(title, artist, artwork, tracks)
      end
    end

    albums
  end

  def update
    @song.stop if @song && @song.playing? && @song.paused?
  end

  def draw
    draw_background

    if @in_album_selection
      draw_albums
    else
      draw_tracks
    end

    draw_now_playing if @now_playing
  end

  def draw_background
    draw_quad(0, 0, Gosu::Color::BLACK,
              SCREEN_WIDTH, 0, Gosu::Color::RED,
              0, SCREEN_HEIGHT, Gosu::Color::BLUE,
              SCREEN_WIDTH, SCREEN_HEIGHT, Gosu::Color::BLUE,
              ZOrder::BACKGROUND)
  end

  def draw_albums
    @albums.each_with_index do |album, index|
        row = index / 2
        col = index % 2
    
        x = 100 + col * 200
        y = 50 + row * 250
    
        album.artwork.draw(x, y, ZOrder::ALBUM)
        @font.draw(album.title, x, y + album.artwork.height + 10, ZOrder::UI, 1, 1, Gosu::Color::WHITE)
      end
  end

  def draw_tracks
    album = @albums[@selected_album]
    album.tracks.each_with_index do |track, index|
      x = 100
      y = 100 + index * 40

      if @selected_track == index
        draw_quad(x, y, Gosu::Color::WHITE,
                  SCREEN_WIDTH - 200, y, Gosu::Color::WHITE,
                  x, y + 40, Gosu::Color::BLUE,
                  SCREEN_WIDTH - 200, y + 40, Gosu::Color::BLUE,
                  ZOrder::ALBUM)
      end

      @font.draw(track.name, x, y, ZOrder::TRACK, 1, 1, Gosu::Color::BLACK)
    end

    @font.draw("Back", 100, SCREEN_HEIGHT - 60, ZOrder::UI, 1, 1, Gosu::Color::WHITE)
  end

  def draw_now_playing
    @font.draw("Now Playing:", 500, SCREEN_HEIGHT - 340, ZOrder::UI, 1, 1, Gosu::Color::WHITE)
    @font.draw(@now_playing, 630, SCREEN_HEIGHT - 340, ZOrder::UI, 1, 1, Gosu::Color::YELLOW)
  end

  def needs_cursor?
    true
  end

  def button_down(id)
    case id
    when Gosu::MsLeft
      if @in_album_selection
        select_album
      else
        select_track
      end
    end
  end

  def select_album
    @albums.each_with_index do |album, index|
        row = index / 2
        col = index % 2
    
        x = 100 + col * 200
        y = 50 + row * 250
    
        if mouse_x >= x && mouse_x <= x + album.artwork.width &&
           mouse_y >= y && mouse_y <= y + album.artwork.height
          @selected_album = index
          @selected_track = 0
          @in_album_selection = false
          break
        end
      end
  end

  def select_track
    album = @albums[@selected_album]

    album.tracks.each_with_index do |_track, index|
      x = 100
      y = 100 + index * 40

      if mouse_x >= x && mouse_x <= x + SCREEN_WIDTH - 200 &&
         mouse_y >= y && mouse_y <= y + 40
        if index == album.tracks.length
          @in_album_selection = true
          @selected_album = nil
          @selected_track = nil
        else
          @selected_track = index
          play_track(album.tracks[@selected_track].location)
        end
        break
      elsif mouse_x >= 100 && mouse_x <= 200 &&
            mouse_y >= SCREEN_HEIGHT - 60 && mouse_y <= SCREEN_HEIGHT - 30
        @in_album_selection = true
        @selected_album = nil
        @selected_track = nil
        break
      end
    end
  end

  def play_track(location)
    @song = Gosu::Song.new(location)
    @song.play(false)
    @now_playing = File.basename(location, ".*")
  end
end

MusicPlayer.new.show if __FILE__ == $0
