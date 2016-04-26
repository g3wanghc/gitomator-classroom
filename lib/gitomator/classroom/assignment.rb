require 'gitomator/classroom'

module Gitomator
  module Classroom


    class DuplicateRepoError < StandardError
      def initialize(repo_name)
        super("Invalid config - duplicate repo, #{repo_name}.")
      end
    end



    class Assignment


      #=========================================================================
      # Static factory methods

      class << self
        private :new
      end

      #
      # @param conf_file [String] - Path to a YAML configuration file.
      #
      def self.from_file(conf_file)
        return from_hash(Gitomator::Classroom::Util.load_config(conf_file))
      end

      #
      # @param conf_data [Hash] - Configuration data (e.g. parsed from a YAML file)
      #
      def self.from_hash(conf_data)
        return new(conf_data)
      end


      #=========================================================================

      # @return Symbol, default is :read
      attr_reader :default_access_permission

      #
      # @param config [Hash] Configuration data (e.g. parsed from a YAML file)
      #
      def initialize(config, repos_key='repos')
        @config = config
        @default_access_permission= (config['default_access_permission'] || :read).to_sym
        @repo2permissions = parse_repo2permissions(config[repos_key] || [])

        # Create an attr_accessor for keys in the config file
        config.reject {|k,_| k.to_s == repos_key} .each do |key, value|
          setter = "#{key}="
          self.class.send(:attr_accessor, key) if !respond_to?(setter)
          send setter, value
        end
      end



      def method_missing(method_sym, *arguments, &block)
        return nil
      end



      #
      # @return # Iterable<Strings>
      #
      def repos
        @repo2permissions.keys
      end

      #
      # @param repo [String] The name of the repository
      #
      # @return Hash<String,Symbol>, mapping name (user or team) to symbol (:read/:write/:admin)
      #
      def permissions(repo)
        @repo2permissions[repo]
      end



      #
      # @param repos_config [Array] Array of repo config items (various formats are supported)
      #
      def parse_repo2permissions(repos_config)
        repo2permissions = {}

        repos_config.each do |repo_config|
          # Repo-name only, no access-permissions specified
          if repo_config.is_a? String
            raise DuplicateRepoError.new "Duplicate repo, #{repo_config}" if repo2permissions.has_key? repo_config
            repo2permissions[repo_config] = {}

          # Repo-name to access-permissions configuration
          elsif (repo_config.is_a? Hash) and (repo_config.length == 1)
            repo_name   = repo_config.keys.first.to_s
            permissions = parse_permissions(repo_config[repo_name])
            raise DuplicateRepoError.new "Duplicate repo, #{repo_name}" if repo2permissions.has_key? repo_name
            repo2permissions[repo_name] = permissions

          # Otherwise, invalid
          else
            raise "Invalid repo config item: #{repo_config}\n" +
                "Expected a String or a Hash with one entry (mapping repo name " +
                "to access-ppermission configuration)."
          end
        end

        return repo2permissions
      end


      #
      # Parse the permissions configuration of a single repo into a hash that
      # maps user/team names (Strings) to access-permissions (Symbols).
      #
      # Various configuration formats are supported:
      #  * String - Single name, with default permission
      #  * Hash - Maps names to permissions
      #  * Array<String/Hash> - An array mixing both of the previous options.
      #
      # @param permissions_config [String/Hash/Array]
      # @return [Hash<String,Symbol>]
      #
      def parse_permissions(permissions_config)
        if permissions_config.is_a? String
          return { permissions_config => default_access_permission }

        elsif permissions_config.is_a? Hash
          return permissions_config.map {|name,perm| [name, perm.to_sym] } .to_h

        elsif permissions_config.is_a? Array
          return permissions_config.map {|x| parse_permissions(x) } .reduce(:merge)

        else
          raise "Invalid permission configuration, #{permissions_config}"
        end
      end


    end
  end
end
