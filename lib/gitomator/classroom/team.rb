require 'gitomator/classroom'

module Gitomator
  module Classroom
    class Team


      #=========================================================================
      # Static factory methods

      #
      # @param conf_file [String/File] - Path to a YAML configuration file.
      #
      def self.from_file(conf_file)
        return from_hash(Gitomator::Classroom::Util.load_config(conf_file))
      end

      #
      # @param config [Hash] - Configuration data (e.g. parsed from a YAML file)
      #
      def self.from_hash(config)
        raise "Team config should include a single entry." if config.length > 1
        return new(config.keys.first, config.values.first)
      end


      #
      # @param conf_file [String/File] - Path to a YAML configuration file.
      # @return Hash[String -> Gitomator::Classroom::Team] Name to team.
      #
      def self.teams_from_file(conf_file)
        return teams_from_hash(Gitomator::Classroom::Util.load_config(conf_file))
      end

      #
      # @param config [Hash] - Configuration data (e.g. parsed from a YAML file)
      # @return Hash[String -> Gitomator::Classroom::Team] Name to team.
      #
      def self.teams_from_hash(config)
        result = {}
        config.each {|name, members| result[name] = new(name, members) }
        return result
      end


      #=========================================================================


      #
      # @param name [String]
      # @param members_config [Array] Each item is either a string (username) or Hash with one entry (username -> role)
      #
      def initialize(name, members_config)
        @name    = name
        @members = parse_members_config(members_config)
      end



      attr_reader :name, :members  # Hash[String -> String], username to role


      def parse_members_config(members_config)
        result = {}

        members_config.each do |entry|
          if entry.is_a? String
            result[entry] = 'member' # Default role is 'member'
          elsif entry.is_a?(Hash) && entry.length == 1
            result[entry.keys.first] = entry.values.first
          else
            raise "Invalid team-member config, #{entry}."
          end
        end

        return result

      end

    end
  end
end
