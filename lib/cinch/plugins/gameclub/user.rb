module Cinch
  module Plugins
    class Gameclub
      class User
        attr_accessor :nick, :steamid, :aliases, :games

        def initialize(nick, steamid)
          @nick = nick
          @steamid = steamid
          @aliases = []
          @games = []
        end

        def refresh_games
          id = SteamId.from_steam_id(steamid)
          steam_games = id.games
          games = steam_games & @gameclub_games
        end

        def save
          @storage.data[:users][nick] = User.new(nick, steamid, aliases, games)
          @storage.synced_save(@bot)
        end

        def self.get(nick)
          @storage.data[:users][nick]
        end
      end
    end
  end
end
