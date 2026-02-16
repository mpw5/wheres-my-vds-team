# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

module Vds
  module GraphQlClient
    ENDPOINT = 'https://api-pdcvds.mwmbwls.co.uk/graphql'

    HTTP = GraphQL::Client::HTTP.new(ENDPOINT) do
      def headers(_context)
        {
          'Content-Type' => 'application/json',
          'Accept' => 'application/graphql-response+json'
        }
      end
    end

    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  end
end
