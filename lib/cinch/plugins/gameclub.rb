require 'steam-condenser'
require 'cinch-storage'

module Cinch::Plugins
  class Gameclub
    include Cinch::Plugin

    def initialize(*args)
      super
      @storage = CinchStorage.new(config[:filename] || 'yaml/gameclub.yml')
      @storage.data[:users] ||= {}
      @steam_games = {
                       440    => 'Team Fortress 2',
                       500    => 'Left 4 Dead',
                       550    => 'Left 4 Dead 2',
                       620    => 'Portal 2',
                       630    => 'Alien Swarm',
                       8980   => 'Borderlands',
                       35720  => 'Trine 2',
                       42910  => 'Magicka',
                       49520  => 'Borderlands 2',
                       63200  => 'Monday Night Combat',
                       65800  => 'Dungeon Defenders',
                       105600 => 'Terraria',
                       113020 => 'Monaco',
                       200710 => 'Torchlight II',
                       201790 => 'Orcs Must Die 2',
                       204300 => 'Awesomenauts',
                       218230 => 'Planetside 2',
                       901566 => 'Borderlands: GOTY'
                     }
      @gameclub_free_games = [ 440, 630, 218230 ]
      @gameclub_games = @steam_games.keys - @gameclub_free_games
      # = config[:steam_apikey]

    end
    
    match /gameclub ([^\s]+)(?:\s(.+))?/

    def execute(m, command, args = nil)
      case command
      when 'help'
        m.user.msg gameclub_text(:help)
      when 'join'
        m.user.msg user_join(m.user.nick)
      when 'leave'
        m.user.msg user_leave(m.user.nick)

      # Group up options that require user to have joined
      when 'play','config','games'
        @user = get_user(m.user.nick)
        if !m.channel.nil? || @user.nil?
          m.user.msg gameclub_text(@user.nil? ? :error_user : :error_not_in_chan)
          return
        end

        case command
        when 'play'
          user_play(@user, args)
        when 'config'
          m.user.msg user_config(@user, args)
        when 'games'
          user_games(@user, args)
        end
      else
        'Unrecognized command'
      end
    end

    private

    def user_join(nick)
      if @storage.data[:users].key?(nick)
        gameclub_text(:error_already_joined)
      else
        @storage.data[:users][nick] = User.new(:nick => nick, :steamid => nil, :aliases => [], :games => [])
        @storage.synced_save(@bot)
        gameclub_text(:joined)
      end
    end

    def user_leave(nick)
      if @storage.data[:users].key?(nick)
        @storage.data[:users].delete(nick)
        @storage.synced_save(@bot)
        gameclub_text(:left)
      else
        gameclub_text(:error_already_left)
      end
    end

    def user_config(user, options = nil)
      return gameclub_text(:help_config) if options.nil? || !options.match(/\A([^\s]+) ([^\s]+)\z/)

      options = options.split(' ')
      case options[0]
      when 'steamid'
        user.steamid = options[1]
        user.refresh_games
        user.save
        message = "You have successfully added your Steam ID (and games), use the games command to manage them."
      when 'alias'
        user.aliases << options[1]
      else
        'Unknown config option'
      end
      @storage.data[:users][user.nick] = user
      @storage.synced_save(@bot)
      return message
    end

    def user_games(user, options = nil)
      return gameclub_text(:error_no_steamid) if user.steamid.nil?
      return gameclub_text(:help_games) if options.nil?
    end

    def user_play(user, options = nil)
      return gameclub_text(:error_no_steamid) if user.steamid.nil?

    end

    def get_user(nick)
      @storage.data[:users][nick] || nil
    end

    def refresh_games(user)
      user.games = SteamId.new(user.steamid).games.keys & @gameclub_games

    end

    def gameclub_text(text)
      case text
      when :help
        'Gameclub!'
      when :joined
        'Welcome to Gameclub!'
      when :left
        'Sorry to see you go, you are now removed from Gameclub.'

      when :error_not_in_chan
        'I do not respond to that command in the channel, only via PM.'
      when :error_user
        'Something went wrong!'
      when :error_no_steamid
        'Sorry you need to add a SteamID before you can do that.'
      when :error_already_joined
        'You\'ve already joined Gameclub!'
      when :error_already_left
        'You\'re not a member of Gameclub, so you can\'t leave it!'

      when :help_config
        'Specify a steam id by using .config steamid YOUR_STEAM_ID'
      when :help_games
        'blah'
      else
        debug "Response text for '#{text}' is not defined"
        raise
      end
    end
  end
end
