# frozen_string_literal: true

module Vds
  module Queries
    TEAMS = Vds::GraphQlClient::Client.parse <<-GRAPHQL
      query($year: Int!, $gender: Gender!) {
        teams(year: $year, gender: $gender) {
          nodes {
            name
            manager {
              displayName
            }
            riders {
              nodes {
                rider {
                  fullName
                }
              }
            }
          }
        }
      }
    GRAPHQL

    RACES = Vds::GraphQlClient::Client.parse <<-GRAPHQL
      query($year: Int!, $gender: Gender!) {
        races(year: $year, gender: $gender) {
          nodes {
            startDate
            stageCount
            race {
              name
            }
          }
        }
      }
    GRAPHQL

    RIDERS = Vds::GraphQlClient::Client.parse <<-GRAPHQL
      query($year: Int!, $gender: Gender!) {
        riders(year: $year, gender: $gender) {
          nodes {
            displayName
            nationality
            season(year: $year, gender: $gender) {
              cost
              previousYearCost
              previousYearScore
              team
            }
          }
        }
      }
    GRAPHQL
  end
end
