require 'dry-struct'
require 'dry-types'
require 'yaml'

module Pharos
  module Kube
    # @see https://godoc.org/k8s.io/client-go/tools/clientcmd/api/v1#Config
    class Config < Dry::Struct
      class Types
        include Dry::Types.module
      end

      class Cluster < Dry::Struct
        attribute :server, Types::String
        attribute :insecure_skip_tls_verify, Types::Bool.optional.default(nil)
        attribute :certificate_authority, Types::String.optional.default(nil)
        attribute :certificate_authority_data, Types::String.optional.default(nil)
        attribute :extensions, Types::Strict::Array.optional.default(nil)
      end
      class NamedCluster < Dry::Struct
        attribute :name, Types::String
        attribute :cluster, Cluster
      end

      class User < Dry::Struct
        attribute :client_certificate, Types::String.optional.default(nil)
        attribute :client_certificate_data, Types::String.optional.default(nil)
        attribute :client_key, Types::String.optional.default(nil)
        attribute :client_key_data, Types::String.optional.default(nil)
        attribute :token, Types::String.optional.default(nil)
        attribute :tokenFile, Types::String.optional.default(nil)
        attribute :as, Types::String.optional.default(nil)
        attribute :as_groups, Types::Array.of(Types::String).optional.default(nil)
        attribute :as_user_extra, Types::Hash.optional.default(nil)
        attribute :username, Types::String.optional.default(nil)
        attribute :password, Types::String.optional.default(nil)
        attribute :auth_provider, Types::Strict::Hash.optional.default(nil)
        attribute :exec, Types::Strict::Hash.optional.default(nil)
        attribute :extensions, Types::Strict::Array.optional.default(nil)
      end
      class NamedUser < Dry::Struct
        attribute :name, Types::String
        attribute :user, User
      end

      class Context < Dry::Struct
        attribute :cluster, Types::Strict::String
        attribute :user, Types::Strict::String
        attribute :namespace, Types::Strict::String.optional.default(nil)
        attribute :extensions, Types::Strict::Array.optional.default(nil)
      end
      class NamedContext < Dry::Struct
        attribute :name, Types::String
        attribute :context, Context
      end

      attribute :kind, Types::Strict::String.optional.default(nil)
      attribute :apiVersion, Types::Strict::String.optional.default(nil)
      attribute :preferences, Types::Strict::Hash.optional
      attribute :clusters, Types::Strict::Array.of(NamedCluster)
      attribute :users, Types::Strict::Array.of(NamedUser)
      attribute :contexts, Types::Strict::Array.of(NamedContext)
      attribute :current_context, Types::Strict::String
      attribute :extensions, Types::Strict::Array.optional.default(nil)

      # recursively transform YAML keys to ruby attribute symbols
      def self.transform_yaml(value)
        case value
        when Hash
          Hash[value.keys.map{|key|
            [key.gsub('-', '_').to_sym, transform_yaml(value[key])]
          }]
        when Array
          value.map{|v| transform_yaml(v)}
        else
          value
        end
      end

      # @param path [String]
      # @return [Pharos::Kube::Config]
      def self.load_file(path)
        return new(transform_yaml(YAML.load_file(path)))
      end

      # TODO: raise error if not found
      # @return [Pharos::Kube::Config::Context]
      def context(name = current_context)
        contexts.find{|context| context.name == name}.context
      end

      # @return [Pharos::Kube::Config::Cluster]
      def cluster(name = context.cluster)
        clusters.find{|cluster| cluster.name == name}.cluster
      end

      # @return [Pharos::Kube::Config::User]
      def user(name = context.user)
        users.find{|user| user.name == name}.user
      end
    end
  end
end
