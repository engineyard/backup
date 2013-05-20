# encoding: utf-8
require 'mail'

module Backup
  module Notifier
    class Mail < Base

      ##
      # Mail delivery method to be used by the Mail gem.
      #
      # Supported methods:
      #
      # [:smtp - ::Mail::SMTP (default)]
      #   Settings used by this method:
      #   {#address}, {#port}, {#domain}, {#user_name}, {#password},
      #   {#authentication}, {#encryption}, {#openssl_verify_mode}
      #
      # [:sendmail - ::Mail::Sendmail]
      #   Settings used by this method:
      #   {#sendmail_args}
      #
      # [:exim - ::Mail::Exim]
      #   Settings used by this method:
      #   {#exim_args}
      #
      # [:file - ::Mail::FileDelivery]
      #   Settings used by this method:
      #   {#mail_folder}
      #
      attr_accessor :delivery_method

      ##
      # Sender Email Address
      attr_accessor :from

      ##
      # Receiver Email Address
      attr_accessor :to

      ##
      # SMTP Server Address
      attr_accessor :address

      ##
      # SMTP Server Port
      attr_accessor :port

      ##
      # Your domain (if applicable)
      attr_accessor :domain

      ##
      # SMTP Server Username (sender email's credentials)
      attr_accessor :user_name

      ##
      # SMTP Server Password (sender email's credentials)
      attr_accessor :password

      ##
      # Authentication type
      #
      # Acceptable values: +:plain+, +:login+, +:cram_md5+
      attr_accessor :authentication

      ##
      # Set the method of encryption to be used for the +SMTP+ connection.
      #
      # [:none (default)]
      #   No encryption will be used.
      #
      # [:starttls]
      #   Use +STARTTLS+ to upgrade the connection to a +SSL/TLS+ connection.
      #
      # [:tls or :ssl]
      #   Use a +SSL/TLS+ connection.
      attr_accessor :encryption

      ##
      # OpenSSL Verify Mode
      #
      # Valid modes: +:none+, +:peer+, +:client_once+, +:fail_if_no_peer_cert+
      # See +OpenSSL::SSL+ for details.
      #
      # Use +:none+ for a self-signed and/or wildcard certificate
      attr_accessor :openssl_verify_mode

      ##
      # Optional arguments to pass to `sendmail`
      #
      # Note that this will override the defaults set by the Mail gem
      # (currently: '-i'). So, if set here, be sure to set all the arguments
      # you require.
      #
      # Example: '-i -X/tmp/traffic.log'
      attr_accessor :sendmail_args

      ##
      # Optional arguments to pass to `exim`
      #
      # Note that this will override the defaults set by the Mail gem
      # (currently: '-i -t') So, if set here, be sure to set all the arguments
      # you require.
      #
      # Example: '-i -t -X/tmp/traffic.log'
      attr_accessor :exim_args

      ##
      # Folder where mail will be kept when using the `:file` `delivery_method` option.
      #
      # Default location is '$HOME/Backup/emails'
      attr_accessor :mail_folder

      def initialize(model, &block)
        super
        instance_eval(&block) if block_given?
      end

      private

      ##
      # Notify the user of the backup operation results.
      #
      # `status` indicates one of the following:
      #
      # `:success`
      # : The backup completed successfully.
      # : Notification will be sent if `on_success` is `true`.
      #
      # `:warning`
      # : The backup completed successfully, but warnings were logged.
      # : Notification will be sent, including a copy of the current
      # : backup log, if `on_warning` or `on_success` is `true`.
      #
      # `:failure`
      # : The backup operation failed.
      # : Notification will be sent, including a copy of the current
      # : backup log, if `on_failure` is `true`.
      #
      def notify!(status)
        name, send_log =
            case status
            when :success then [ 'Success', false ]
            when :warning then [ 'Warning', true  ]
            when :failure then [ 'Failure', true  ]
            end

        email = new_email
        email.subject = "[Backup::%s] #{@model.label} (#{@model.trigger})" % name
        template = Backup::Template.new({:model => model})
        email.body = template.result('notifier/mail/%s.erb' % status.to_s)

        if send_log
          email.convert_to_multipart
          email.attachments["#{@model.time}.#{@model.trigger}.log"] = {
            :mime_type => 'text/plain;',
            :content   => Logger.messages.map(&:formatted_lines).flatten.join("\n")
          }
        end

        email.deliver! # raise error if unsuccessful
      end

      ##
      # Configures the Mail gem by setting the defaults.
      # Creates and returns a new email, based on the @delivery_method used.
      def new_email
        method = %w{ smtp sendmail exim file test }.
            index(@delivery_method.to_s) ? @delivery_method.to_s : 'smtp'

        options =
            case method
            when 'smtp'
              { :address              => @address,
                :port                 => @port,
                :domain               => @domain,
                :user_name            => @user_name,
                :password             => @password,
                :authentication       => @authentication,
                :enable_starttls_auto => @encryption == :starttls,
                :openssl_verify_mode  => @openssl_verify_mode,
                :ssl                  => @encryption == :ssl,
                :tls                  => @encryption == :tls
              }
            when 'sendmail'
              opts = {}
              opts.merge!(:location  => utility(:sendmail))
              opts.merge!(:arguments => @sendmail_args) if @sendmail_args
              opts
            when 'exim'
              opts = {}
              opts.merge!(:location  => utility(:exim))
              opts.merge!(:arguments => @exim_args) if @exim_args
              opts
            when 'file'
              @mail_folder ||= File.join(Config.root_path, 'emails')
              { :location => File.expand_path(@mail_folder) }
            when 'test' then {}
            end

        ::Mail.defaults do
          delivery_method method.to_sym, options
        end

        email = ::Mail.new
        email.to   = @to
        email.from = @from
        email
      end

      attr_deprecate :enable_starttls_auto, :version => '3.2.0',
                     :message => "Use #encryption instead.\n" +
                        'e.g. mail.encryption = :starttls',
                     :action => lambda {|klass, val|
                       klass.encryption = val ? :starttls : :none
                     }

      attr_deprecate :sendmail, :version => '3.6.0',
          :message => 'Use Backup::Utilities.configure instead.',
          :action => lambda {|klass, val|
            Utilities.configure { sendmail val }
          }

      attr_deprecate :exim, :version => '3.6.0',
          :message => 'Use Backup::Utilities.configure instead.',
          :action => lambda {|klass, val|
            Utilities.configure { exim val }
          }

    end
  end
end
