require 'jackal-assets'

module Jackal
  module Assets
    # Object storage helper
    class Store

      # @return [String] bucket name
      attr_accessor :bucket
      # @return [Hash] initializer arguments
      attr_reader :arguments
      # @return [Object] remote connection if applicable
      attr_reader :connection

      # Create new instance
      #
      # @param args [Hash]
      # @option args [String] :bucket bucket name
      # @option args [String] :provider provider name
      def initialize(args={})
        @arguments = args.to_smash
        @connection_arguments = args[:connection]
        @bucket_name = args[:bucket]
        setup
      end

      # @return [String] name of bucket
      def bucket_name
        @bucket_name ||
          Carnivore::Config.get(:jackal, :assets, :bucket)
      end

      # @return [Smash] connection arguments
      def connection_arguments
        (@connection_arguments ||
          Carnivore::Config.get(:jackal, :assets, :connection) ||
          Smash.new).to_smash
      end

      # Setup API connection and storage bucket
      def setup
        Carnivore.configure!(:verify)
        @connection = Miasma.api(
          connection_arguments.deep_merge(
            Smash.new(
              :type => :storage
            )
          )
        )
        @bucket = @connection.buckets.build(:name => bucket_name).save
      end

      # Fetch object
      #
      # @param key [String]
      # @return [File]
      def get(key)
        remote_file = bucket.files.reload.get(key)
        if(remote_file)
          remote_file.body
        else
          raise Error::NotFound.new "Remote file does not exist! (<#{bucket}>:#{key})"
        end
      end

      # Store object
      #
      # @param key [String]
      # @param file [File]
      # @return [TrueClass]
      def put(key, file)
        remote_file = bucket.files.reload.get(key) ||
          bucket.files.build(:name => key)
        remote_file.body = file
        remote_file.save
        true
      end

      # Delete object
      #
      # @param key [String]
      # @return [TrueClass, FalseClass]
      def delete(key)
        remote_file = bucket.files.reload.get(key)
        if(remote_file)
          remote_file.destroy
          true
        else
          false
        end
      end

      # URL for object
      #
      # @param key [String]
      # @param expires_in [Numeric] number of seconds url is valid
      # @return [String]
      def url(key, expires_in=nil)
        remote_file = bucket.files.reload.get(key)
        if(remote_file)
          remote_file.url(expires_in)
        else
          raise Error::NotFound.new "Remote file does not exist! (<#{bucket}>:#{key})"
        end
      end

    end
  end
end
