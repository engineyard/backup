# encoding: utf-8

##
# Only load the Fog gem when the Backup::Storage::Engineyard class is loaded

module Backup
  module Storage
    class EngineYard < Base

      ##
      # Engine Yard Instance Credentials
      attr_accessor :instance_token

      ##
      # Core API URL 
      attr_accessor :core_api_url

      ##
      # Creates a new instance of the storage object
      def initialize(model, storage_id = nil, &block)
        super(model, storage_id)
        instance_eval(&block) if block_given?
      end

      private

      def connection
        #send core-client a request with a given token, receive a url
        @connection ||= Ey::Core::Client.new(
          :token  => instance_token,
          :url    => core_api_url,
          :logger => (ENV["VERBOSE"] ? Logger.new(STDOUT) : nil),
        )
      end

      ##
      # Transfers the archived file to the specified container
      def transfer!
        backup = connection.backups.create
        Logger.message "Created backup [#{backup.id}]"

        files_to_transfer_for(@package) do |local_file, remote_file|
          backup_file = backup.files.create(filename: remote_file)
          Logger.message "Created backup file [#{backup_file.id}]"

          Logger.message "#{storage_name} performing upload of '#{File.join(local_path, local_file)}' to '#{backup_file.upload_url}'."
          backup_file.upload(file: File.join(local_path, local_file))
        end

        Logger.message "Finished uploading files for backup [#{backup.id}]"
      end

      ##
      # Removes the transferred archive file(s) from the storage location.
      # Any error raised will be rescued during Cycling
      # and a warning will be logged, containing the error message.
      def remove!(package)
        raise NotImplementedError
      end
    end
  end
end

