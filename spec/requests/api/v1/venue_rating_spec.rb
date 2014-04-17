require 'spec_helper'

describe 'Venue rating spec' do
  describe :create do
    let(:params) { { rating: 3.0 } }

    let(:venue) { create(:venue) }
    let(:user) { create(:user) }

    it 'should be able to create' do
      post api_v1_venue_venue_ratings_path(venue),
        { auth_token: user.authentication_token, rating: 2 }

      json = JSON.parse(response.body)

      venue_rating = VenueRating.last
      expect(json['id']).to eq(venue_rating.id)
      expect(json['venue_id']).to eq(venue.id)
      expect(json['user_id']).to eq(user.id)
    end

    it 'should return error if rating is blank' do
      post api_v1_venue_venue_ratings_path(venue),
        { auth_token: user.authentication_token }

      json = JSON.parse(response.body)

      expect(json['errors']['rating']).to eq(["can't be blank"])
    end
  end
end
