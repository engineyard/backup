# encoding: utf-8

module Backup
  module Database
    class MySQL < Base
      class Error < Backup::Error; end

      ##
      # Name of the database that needs to get dumped
      # To dump all databases, set this to `:all` or leave blank.
      attr_accessor :name

      ##
      # Credentials for the specified database
      attr_accessor :username, :password

      ##
      # Connectivity options
      attr_accessor :host, :port, :socket

      ##
      # Tables to skip while dumping the database
      #
      # If `name` is set to :all (or not specified), these must include
      # a database name. e.g. 'name.table'.
      # If `name` is given, these may simply be table names.
      attr_accessor :skip_tables

      ##
      # Tables to dump. This in only valid if `name` is specified.
      # If none are given, the entire database will be dumped.
      attr_accessor :only_tables

      ##
      # Additional "mysqldump" options
      attr_accessor :additional_options

      ##
      # Single transaction ?
      attr_accessor :single_transaction

      ##
      # Forces mysql to lock database for writes until the dump is completed
      # it will also save binlog info before the dump runs
      attr_accessor :lock

      def initialize(model, database_id = nil, &block)
        super
        instance_eval(&block) if block_given?

        @name ||= :all
      end

      ##
      # Performs the mysqldump command and outputs the dump file
      # in the +dump_path+ using +dump_filename+.
      #
      #   <trigger>/databases/MySQL[-<database_id>].sql[.gz]
      def perform!
        super

        pipeline = Pipeline.new

        lock_database if @lock
        dump_ext = 'sql'

        pipeline << mysqldump

        model.compressor.compress_with do |command, ext|
          pipeline << command
          dump_ext << ext
        end if model.compressor

        pipeline << "#{ utility(:cat) } > " +
            "'#{ File.join(dump_path, dump_filename) }.#{ dump_ext }'"

        pipeline.run
        if pipeline.success?
          log!(:finished)
        else
          raise Error, "Dump Failed!\n" + pipeline.error_messages
        end
      ensure
        unlock_database if @lock
      end

      private

      def mysqldump
        "#{ utility(:mysqldump) } #{ credential_options } " +
        "#{ connectivity_options } #{ user_options } #{ name_option } " +
        "#{ tables_to_dump } #{ tables_to_skip }"
      end

      def credential_options
        opts = []
        opts << "--user='#{ username }'" if username
        opts << "--password='#{ password }'" if password
        opts.join(' ')
      end

      def connectivity_options
        return "--socket='#{ socket }'" if socket

        opts = []
        opts << "--host='#{ host }'" if host
        opts << "--port='#{ port }'" if port
        opts.join(' ')
      end

      def user_options
        Array(additional_options).join(' ')
      end

      def name_option
        dump_all? ? '--all-databases' : name
      end

      def tables_to_dump
        Array(only_tables).join(' ') unless dump_all?
      end

      def tables_to_skip
        Array(skip_tables).map do |table|
          table = (dump_all? || table['.']) ? table : "#{ name }.#{ table }"
          "--ignore-table='#{ table }'"
        end.join(' ')
      end

      def dump_all?
        name == :all
      end

      def lock_database
        lock_command = <<-EOS.gsub(/^ +/, '')
          mysql -e 'SET GLOBAL READ_ONLY = 1'
        EOS

        run(lock_command)
        fetch_metadata
      end

      def unlock_database
        binding.pry
        unlock_command = <<-EOS.gsub(/^ +/, '')
          mysql -e 'SET GLOBAL READ_ONLY = 0'
        EOS

        run(unlock_command)
      end

      def fetch_metadata
        replica_info_command = 'mysql -e "SHOW SLAVE STATUS\G"'
        master_info_command = 'mysql -e "SHOW MASTER STATUS\G"'

        # save all the info in the node in a hash for ey-core
        backup_metadata = Hash.new
        backup_metadata['replica_info'] = run(replica_info_command)
        backup_metadata['master_info'] = run(master_info_command)

        backup_metadata
      end

      def db_has_myisam?
        #detect if any tables are myisam
      end
    end
  end
end
