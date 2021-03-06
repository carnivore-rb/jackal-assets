require 'jackal-assets'
require 'tempfile'
require 'zip'

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
        @bucket = @connection.buckets.get(bucket_name)
        unless(@bucket)
          @bucket = @connection.buckets.build(:name => bucket_name).save
        end
      end

      # Fetch object
      #
      # @param key [String]
      # @return [File]
      def get(key)
        remote_file = bucket.files.filter(:prefix => key).detect do |item|
          item.name == key
        end
        if(remote_file)
          io = remote_file.body.io
          if(io.respond_to?(:path))
            io.rewind
            if(block_given?)
              begin
                while(data = io.readpartial(2048))
                  yield data
                end
              rescue EOFError
              end
            end
            io.rewind
            io
          else
            e_file = Bogo::EphemeralFile.new('jackal-asset')
            e_file.binmode
            begin
              while(data = io.readpartial(2048))
                e_file.write data
                if(block_given?)
                  yield data
                end
              end
            rescue EOFError
            end
            e_file.flush
            e_file.rewind
            e_file
          end
        else
          raise Error::NotFound.new "Remote file does not exist! (<#{bucket.name}>:#{key})"
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

      # Pack directory into compressed file
      #
      # @param directory [String]
      # @param name [String] tmp file base name
      # @return [File]
      def pack(directory, name=nil)
        tmp_file = Tempfile.new(name || File.basename(directory))
        file_path = "#{tmp_file.path}.zip"
        tmp_file.delete
        entries = Hash[
          Dir.glob(File.join(directory, '**', '{*,.*}')).map do |path|
            next if path.end_with?('.')
            [path.sub(%r{#{Regexp.escape(directory)}/?}, ''), path]
          end
        ]
        Zip::File.open(file_path, Zip::File::CREATE) do |zipfile|
          entries.keys.sort.each do |entry|
            path = entries[entry]
            if(File.directory?(path))
              zipfile.mkdir(entry.dup)
            else
              zipfile.add(entry, path)
            end
          end
        end
        file = File.open(file_path, 'rb')
        file
      end

      # Unpack object
      #
      # @param object [File]
      # @param destination [String]
      # @param args [Symbol] argument list (:disable_overwrite)
      # @return [String] destination
      def unpack(object, destination, *args)
        if(File.exists?(destination) && args.include?(:disable_overwrite))
          destination
        else
          unless(File.directory?(destination))
            FileUtils.mkdir_p(destination)
          end
          if(object.respond_to?(:path))
            to_unpack = object.path
          elsif(object.respond_to?(:io))
            to_unpack = object.io
          else
            to_unpack = object
          end
          zfile = Zip::File.new(to_unpack)
          zfile.restore_permissions = true
          zfile.each do |entry|
            new_dest = File.join(destination, entry.name)
            if(File.exists?(new_dest))
              FileUtils.rm_rf(new_dest)
            end
            entry.restore_permissions = true
            entry.extract(new_dest)
          end
          destination
        end
      end

    end
  end
end
